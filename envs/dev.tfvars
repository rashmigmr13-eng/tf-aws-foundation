
tregion                   = "ap-south-1"
environment              = "dev"
vpc_cidr                 = "10.10.0.0/16"
az_count                 = 2
single_nat_gateway       = true # 1 NAT = cheapest
instance_types           = ["t3.micro", "t3a.micro"]
asg_min                  = 1
asg_max                  = 2
asg_desired              = 1
on_demand_base           = 0
on_demand_pct_above_base = 0 # 100% Spot
db_instance_class        = "db.t4g.micro"
db_multi_az              = false
db_backup_days           = 1
protect                  = false
enable_nat = false
alert_email = "rashmiravi803@gmail.com" # CHANGE ME
monthly_budget_usd = 20
