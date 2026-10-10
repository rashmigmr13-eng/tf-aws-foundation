# Results log

## Time to provision a full environment (`terraform apply` from empty state)
| env | date | duration |
|-----|------|----------|

## Manual steps, before vs after
| Task | Before (console/CLI) | After (Terraform + CI) |
|------|----------------------|------------------------|
| VPC, subnets, routes, NAT, endpoints | | 0 |
| ALB, target group, listeners | | 0 |
| Launch template, ASG, scaling policies | | 0 |
| Multi-AZ RDS, SGs, subnet group | | 0 |
| IAM roles/profiles | | 0 |
| Replicate to stage and prod | | 0 (edit tfvars) |
| Deploy | | 1 (approve prod) |
Count the console clicks/CLI commands honestly for "before" by doing one env by hand once.

## Break-it drills
| Drill | What I did | Observed | Recovery time |
|-------|------------|----------|---------------|
| State lock | 2 concurrent applies | | |
| Drift | deleted ALB listener | | |
| State corruption | overwrote state, restored S3 version | | |

## Cost (infracost, monthly)
| env | estimate |
|-----|----------|
