variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "do_ssh_private_key" {
  description = "DigitalOcean SSH Private Key"
  type        = string
  sensitive   = true
}

variable "project_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "mesazon-dev"
}
