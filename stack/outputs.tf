output "alb_dns" { value = module.alb.dns_name }
output "db_endpoint" { value = module.rds.endpoint }
output "db_secret_arn" { value = module.rds.secret_arn }
output "asg_name" { value = module.asg.asg_name }
output "dashboard" { value = module.observability.dashboard_name }
