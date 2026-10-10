variable "name" { type = string }
variable "cidr" { type = string }
variable "az_count" {
  type    = number
  default = 2
}
variable "single_nat_gateway" {
  description = "true = one NAT (cheap, dev/stage). false = one per AZ (HA, prod)."
  type        = bool
  default     = true
}
variable "enable_nat" {
  description = "false = no NAT gateway (free-tier lab mode: app runs in public subnets, locked to the ALB by SG)"
  type        = bool
  default     = true
}
