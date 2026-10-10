#!/usr/bin/env bash
# Usage: scripts/measure.sh dev  -> times a full provision, appends to docs/RESULTS.md
set -euo pipefail
ENV=${1:?env}; cd "$(dirname "$0")/../stack"
terraform init -reconfigure -backend-config=../envs/$ENV.backend.hcl >/dev/null
START=$(date +%s)
terraform apply -auto-approve -var-file=../envs/$ENV.tfvars
END=$(date +%s)
printf "| %s | %s | %d min %d s |\n" "$ENV" "$(date -u +%F)" $(((END-START)/60)) $(((END-START)%60)) >> ../docs/RESULTS.md
echo "Provisioned $ENV in $((END-START))s"
