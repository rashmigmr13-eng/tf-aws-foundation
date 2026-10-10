# Prod TOPOLOGY at minimum size: multi-AZ ASG + Multi-AZ RDS + NAT per AZ.
# Run for a few hours for HA/failover drills, then destroy. Never leave running.
region                   = "ap-south-1"
environment              = "prodlite"
vpc_cidr                 = "10.40.0.0/16"
az_count                 = 2
single_nat_gateway       = false
enable_nat               = true
instance_types           = ["t3.micro", "t3a.micro"]
asg_min                  = 2
asg_max                  = 4
asg_desired              = 2
on_demand_base           = 2
on_demand_pct_above_base = 0
db_instance_class        = "db.t4g.micro"
db_multi_az              = true
db_backup_days           = 1
protect                  = false
alert_email              = "you@example.com" # CHANGE ME
monthly_budget_usd       = 20
