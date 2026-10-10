#!/usr/bin/env bash
# Chaos drills against DEV only. Usage: scripts/break-it.sh {lock|drift|corrupt}
set -euo pipefail
cd "$(dirname "$0")/../stack"
ENV=dev
BUCKET=$(grep ^bucket ../envs/$ENV.backend.hcl | cut -d'"' -f2)
KEY=$(grep ^key ../envs/$ENV.backend.hcl | cut -d'"' -f2)
TABLE=$(grep ^dynamodb_table ../envs/$ENV.backend.hcl | cut -d'"' -f2)
init() { terraform init -reconfigure -backend-config=../envs/$ENV.backend.hcl >/dev/null; }
APPLY="terraform apply -auto-approve -var-file=../envs/$ENV.tfvars"

case "${1:-}" in
lock)   # Drill 1: two concurrent applies -> 2nd must fail with "Error acquiring the state lock"
  init
  touch /tmp/force-change; $APPLY -lock-timeout=0s > /tmp/apply1.log 2>&1 &
  sleep 10
  $APPLY -lock-timeout=0s 2>&1 | tee /tmp/apply2.log || true
  grep -qi "state lock" /tmp/apply2.log && echo "PASS: lock blocked 2nd apply" || echo "FAIL: no lock seen (is apply 1 still running?)"
  wait ;;
drift)  # Drill 2: delete the ALB HTTP listener by hand, detect, remediate
  init
  ARN=$(aws elbv2 describe-load-balancers --names "app-$ENV" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
  L=$(aws elbv2 describe-listeners --load-balancer-arn "$ARN" --query 'Listeners[0].ListenerArn' --output text)
  aws elbv2 delete-listener --listener-arn "$L"
  echo ">> Listener deleted by hand. Drift check (exit code 2 = changes pending):"
  terraform plan -detailed-exitcode -var-file=../envs/$ENV.tfvars || echo "exit=$? -> drift detected"
  echo ">> Remediating:"; $APPLY ;;
corrupt) # Drill 3: corrupt state in S3, then restore the previous version
  init
  echo "{ corrupted" > /tmp/bad.tfstate
  aws s3 cp /tmp/bad.tfstate "s3://$BUCKET/$KEY"
  terraform plan -var-file=../envs/$ENV.tfvars 2>&1 | tail -8 || true
  echo ">> Restoring from S3 versioning..."
  PREV=$(aws s3api list-object-versions --bucket "$BUCKET" --prefix "$KEY" \
         --query 'sort_by(Versions,&LastModified)[-2].VersionId' --output text)
  aws s3api copy-object --bucket "$BUCKET" --key "$KEY" --copy-source "$BUCKET/$KEY?versionId=$PREV"
  echo "If Terraform reports a digest/checksum mismatch, update the '$BUCKET/$KEY-md5' item in DynamoDB table $TABLE"
  echo "to the digest shown in the error message, then re-run plan."
  terraform plan -var-file=../envs/$ENV.tfvars | tail -3 ;;
*) echo "usage: $0 {lock|drift|corrupt}"; exit 1 ;;
esac
