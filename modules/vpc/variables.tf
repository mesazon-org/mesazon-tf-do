variable "environment" {
  description = "The environment for which to configure the database."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug (e.g., nyc1)."
  type        = string
}

variable "vpc_name_raw" {
  description = "The raw name for the VPC, which will be combined with the environment and region to create the final name."
  type        = string
}

variable "ip_range" {
  description = "The private IP range for the VPC in CIDR notation."
  type        = string
}
