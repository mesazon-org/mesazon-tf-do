variable "project_id" {
  type        = string
  description = "DigitalOcean Project ID assignment"
}

variable "do_ssh_private_key" {
  description = "DigitalOcean SSH Private Key"
  type        = string
  sensitive   = true
}

variable "team_members" {
  description = "Map of usernames and their SSH public keys"
  type        = map(string)
}

variable "region" {
  type        = string
  description = "DigitalOcean region for resource deployment"
}

variable "size" {
  type        = string
  description = "Droplet size"
}

variable "name" {
  type        = string
  description = "Droplet name"
}

variable "image" {
  type        = string
  description = "Droplet image"
}

variable "environment" {
  type        = string
  description = "environment"
}
