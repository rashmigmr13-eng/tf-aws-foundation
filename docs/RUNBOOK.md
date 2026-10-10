# Runbook

## Alerts (SNS email -> confirm the subscription once!)
| Alarm | Meaning | First actions |
|---|---|---|
| alb-5xx | App returning errors | Check dashboard; `aws autoscaling describe-scaling-activities`; SSM into an instance, check nginx/app logs; roll back last deploy |
| unhealthy-hosts | Targets failing /health | Target group health reasons in console; instance refresh status; SG/port mismatch? |
| latency-p95 | Slow responses | CPU alarm? DB connections/CPU? Scale max too low? |
| asg-cpu-high | Saturation | Confirm scaling policies firing; raise `asg_max` via PR |
| rds-low-storage | Disk filling | Autoscaling storage should grow; check `max_allocated_storage`; find bloat |

## Procedures
- **Deploy infra change**: PR -> review plan + infracost comment -> merge -> dev -> stage auto-apply.
- **Rollback**: `git revert` the commit, merge; pipeline re-applies the previous state of the code.
- **RDS failover drill** (prod-lite): `aws rds reboot-db-instance --db-instance-identifier app-prodlite --force-failover`; record downtime in RESULTS.md.
- **AZ-failure drill**: terminate all instances in one AZ (`aws ec2 terminate-instances`); watch ASG rebalance; ALB keeps serving.
- **Load test / scale-out drill**: `hey -z 5m -c 100 http://<alb_dns>/` and watch ASG add instances.
- **Restore state**: see `scripts/break-it.sh corrupt`.

## Cost control
- Nightly destroy workflow; budget alerts at 50/80/100% (forecast).
- Watch for: NAT gateways, ALBs, RDS Multi-AZ, unattached Elastic IPs, public IPv4 addresses.
