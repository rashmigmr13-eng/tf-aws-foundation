variable "region" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "az_count" { type = number }
variable "single_nat_gateway" { type = bool }
variable "instance_types" { type = list(string) }
variable "asg_min" { type = number }
variable "asg_max" { type = number }
variable "asg_desired" { type = number }
variable "on_demand_base" { type = number }
variable "on_demand_pct_above_base" { type = number }
variable "db_instance_class" { type = string }
variable "db_multi_az" { type = bool }
variable "db_backup_days" { type = number }
variable "protect" {
  description = "Deletion protection + final snapshots (true for prod)"
  type        = bool
}
variable "certificate_arn" {
  type    = string
  default = ""
}
variable "route53_zone_id" {
  type    = string
  default = ""
}
variable "domain_name" {
  type    = string
  default = ""
}
variable "enable_nat" { type = bool }
variable "alert_email" { type = string }
variable "monthly_budget_usd" { type = number }
