variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_id" { type = string }
variable "instance_class" { default = "db.t4g.micro" }
variable "engine_version" { default = "16" }
variable "allocated_storage" { default = 20 }
variable "max_allocated_storage" { default = 100 }
variable "multi_az" { default = false }
variable "backup_retention_days" { default = 7 }
variable "deletion_protection" { default = false }
variable "skip_final_snapshot" { default = true }

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
}
resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "Postgres from app tier only"
  vpc_id      = var.vpc_id
  lifecycle { create_before_destroy = true }
}
resource "aws_vpc_security_group_ingress_rule" "pg" {
  security_group_id            = aws_security_group.db.id
  description                  = "Postgres from app SG"
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_db_instance" "this" {
  identifier                          = var.name
  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage # storage autoscaling
  storage_type                        = "gp3"
  storage_encrypted                   = true
  db_name                             = "app"
  username                            = "dbadmin"
  manage_master_user_password         = true # password lives in Secrets Manager, not in tfvars
  multi_az                            = var.multi_az
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.db.id]
  publicly_accessible                 = false
  backup_retention_period             = var.backup_retention_days
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : "${var.name}-final"
  auto_minor_version_upgrade          = true
  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  copy_tags_to_snapshot               = true
}

output "endpoint" { value = aws_db_instance.this.address }
output "secret_arn" { value = aws_db_instance.this.master_user_secret[0].secret_arn }
output "identifier" { value = aws_db_instance.this.identifier }
