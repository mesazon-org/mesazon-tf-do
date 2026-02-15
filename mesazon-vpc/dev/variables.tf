variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "DigitalOcean project ID where this VPC's resources will be managed"
  type        = string
}
