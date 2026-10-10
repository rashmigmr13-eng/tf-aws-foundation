# Running this on a free AWS account

Accounts created after 2025-07-15 get a credit-based Free Plan (~$100-$200, 6-month window), not the old free
instance hours. Everything below is paid from credits. Verify on the AWS Free Tier page for your account.

| Mode | What runs | Notes |
|---|---|---|
| `dev` | ALB + ASG (t3.micro, public subnets, no NAT) + RDS t4g.micro single-AZ | Cheapest full-stack. ALB + RDS are the main cost. |
| `stage` | Same, slightly larger, 2 instances | Use for pipeline promotion demos. |
| `prod-lite` | 2 AZ, NAT per AZ, Multi-AZ RDS, t3.micro | Real HA behaviour. Run for hours, not days. |
| `prod` | Full-size reference config | PLAN-ONLY in CI. Never applied on free credits. |

Rules: never leave NAT/ALB/Multi-AZ RDS running overnight (workflow does it for you); confirm the budget email;
do NOT join the account to an AWS Organization if you want to keep credits (credits can expire on joining).
Always-free and cheap pieces used: S3 + DynamoDB state, CloudWatch (10 alarms, 3 dashboards), Budgets (2 free), SNS email, SSM.
Not used (cost money or need a domain): WAF, CloudFront+custom domain, ACM/Route 53 hosted zone (zone ~$0.50/mo).
