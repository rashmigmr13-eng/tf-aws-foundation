locals { name = "app-${var.environment}" }

module "vpc" {
  source             = "../modules/vpc"
  name               = local.name
  cidr               = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  enable_nat         = var.enable_nat
}
module "iam" {
  source = "../modules/iam"
  name   = local.name
}
module "alb" {
  source              = "../modules/alb"
  name                = local.name
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  certificate_arn     = var.certificate_arn
  deletion_protection = var.protect
}
module "asg" {
  source                          = "../modules/asg"
  name                            = local.name
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = var.enable_nat ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids
  associate_public_ip             = !var.enable_nat
  alb_security_group_id           = module.alb.security_group_id
  target_group_arns               = [module.alb.target_group_arn]
  alb_resource_label              = "${module.alb.arn_suffix}/${module.alb.tg_arn_suffix}"
  instance_profile_name           = module.iam.instance_profile_name
  instance_types                  = var.instance_types
  min_size                        = var.asg_min
  max_size                        = var.asg_max
  desired_capacity                = var.asg_desired
  on_demand_base_capacity         = var.on_demand_base
  on_demand_percentage_above_base = var.on_demand_pct_above_base
}
module "rds" {
  source                    = "../modules/rds"
  name                      = local.name
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.db_subnet_ids
  allowed_security_group_id = module.asg.security_group_id
  instance_class            = var.db_instance_class
  multi_az                  = var.db_multi_az
  backup_retention_days     = var.db_backup_days
  deletion_protection       = var.protect
  skip_final_snapshot       = !var.protect
}

resource "aws_route53_record" "app" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

module "observability" {
  source         = "../modules/observability"
  name           = local.name
  alert_email    = var.alert_email
  alb_arn_suffix = module.alb.arn_suffix
  tg_arn_suffix  = module.alb.tg_arn_suffix
  asg_name       = module.asg.asg_name
  db_identifier  = module.rds.identifier
}
module "budget" {
  source      = "../modules/budget"
  name        = local.name
  alert_email = var.alert_email
  limit_usd   = var.monthly_budget_usd
}
