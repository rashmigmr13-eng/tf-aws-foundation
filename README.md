# Terraform multi-environment AWS foundation

One codebase (`stack/` + `modules/`), three environments (`envs/{dev,stage,prod}.tfvars`),
three isolated state files in one versioned S3 bucket with DynamoDB locking.

```
Route 53 -> ALB (3 AZs, public subnets)
              -> ASG (private subnets, mixed On-Demand/Spot, target-tracking on CPU + req/target)
                   -> RDS PostgreSQL (isolated db subnets, Multi-AZ in prod, creds in Secrets Manager)
NAT per AZ in prod (1 shared NAT in dev/stage) | S3 gateway endpoint | SSM instead of SSH
```

## Free-tier / credit-friendly operation
See `docs/FREE-TIER.md` and `docs/RUNBOOK.md`. dev/stage run without NAT, `prod-lite` is a short-lived HA drill env, `prod` is plan-only in CI,
and a nightly workflow destroys everything billable. Run `terraform fmt -recursive` once after pulling these changes.

## How each env differs (cost vs availability)
| | dev | stage | prod |
|---|---|---|---|
| AZs | 2 | 2 | 3 |
| NAT | 1 | 1 | 1 per AZ |
| Compute | 100% Spot, 1-2 | 1 On-Demand + Spot, 2-4 | 3 On-Demand base + 70% Spot burst, 3-12 |
| RDS | t4g.micro single-AZ | t4g.small single-AZ | r6g.large Multi-AZ, 14d backups |
| Deletion protection | off | off | on |

## Run order
1. `cd bootstrap && terraform init && terraform apply -var bucket_name=<unique>`  (once)
2. Put the bucket/table names into `envs/*.backend.hcl`.
3. `make apply ENV=dev` (or `scripts/measure.sh dev` to also record the time).
4. Wire CI: create GitHub OIDC roles (plan = read-only, apply = write), set secrets
   `AWS_PLAN_ROLE_ARN`, `AWS_APPLY_ROLE_ARN`, `INFRACOST_API_KEY`; add required reviewers on the `prod` Environment.
5. Drills: `scripts/break-it.sh lock|drift|corrupt`. Record results in `docs/RESULTS.md`.

## Notes
- Terraform >= 1.10 supports `use_lockfile = true` (S3-native locking) as a DynamoDB replacement; this repo uses DynamoDB as requested.
- NOT yet run against a real account: expect to fix small things on first `plan` (e.g. RDS engine version availability in your region).
- Cost: NAT gateways and RDS Multi-AZ dominate. Destroy dev/stage when idle (`terraform destroy`).

## Phase 2 for true real-time workloads
WebSockets already work through the ALB (idle timeout 1h). Add as needed: ElastiCache Redis (pub/sub, sessions),
Kinesis or MSK for event streams, CloudFront + WAF at the edge, RDS read replicas / RDS Proxy, and Karpenter/EKS or Fargate if you outgrow EC2 ASGs.
