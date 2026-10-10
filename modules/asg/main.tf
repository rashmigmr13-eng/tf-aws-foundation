variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "target_group_arns" { type = list(string) }
variable "alb_resource_label" {
  description = "<alb arn_suffix>/<tg arn_suffix> for request-count scaling"
  type        = string
}
variable "instance_profile_name" { type = string }
variable "instance_types" {
  type    = list(string)
  default = ["t3.small"]
}
variable "associate_public_ip" {
  type    = bool
  default = false
}
variable "app_port" {
  type    = number
  default = 80
}
variable "min_size" { type = number }
variable "max_size" { type = number }
variable "desired_capacity" { type = number }
variable "on_demand_base_capacity" {
  type    = number
  default = 0
}
variable "on_demand_percentage_above_base" {
  description = "0 = all Spot above base (cheapest). 100 = all On-Demand."
  type        = number
  default     = 100
}
variable "target_cpu" {
  type    = number
  default = 55
}
variable "target_requests_per_instance" {
  type    = number
  default = 1000
}
variable "user_data" {
  type    = string
  default = ""
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "App instances"
  vpc_id      = var.vpc_id
  lifecycle { create_before_destroy = true }
}
resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from ALB only"
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound via NAT (SSM, package updates)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.name}-"
  image_id    = data.aws_ssm_parameter.ami.value
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.app.id]
    delete_on_termination       = true
  }
  iam_instance_profile { name = var.instance_profile_name }
  metadata_options {
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }
  monitoring { enabled = true }
  user_data = base64encode(var.user_data != "" ? var.user_data : <<-EOT
    #!/bin/bash
    dnf install -y nginx
    echo "ok" > /usr/share/nginx/html/health
    echo "<h1>$(hostname) - ${var.name}</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOT
  )
  tag_specifications {
    resource_type = "instance"
    tags          = { Name = var.name }
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids # spans all AZs
  target_group_arns         = var.target_group_arns
  health_check_type         = "ELB"
  health_check_grace_period = 120
  capacity_rebalance        = true

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = aws_launch_template.this.latest_version
      }
      dynamic "override" {
        for_each = var.instance_types
        content { instance_type = override.value }
      }
    }
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 66
      instance_warmup        = 120
    }
  }
  lifecycle { ignore_changes = [desired_capacity] }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = var.target_cpu
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
  }
}
resource "aws_autoscaling_policy" "requests" {
  name                   = "${var.name}-requests"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = var.target_requests_per_instance
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_resource_label
    }
  }
}

output "security_group_id" { value = aws_security_group.app.id }
output "asg_name" { value = aws_autoscaling_group.this.name }
