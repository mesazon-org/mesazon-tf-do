variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
  sensitive   = true
}

variable "project_id" {
  type = string
}

variable "cluster_enabled" {
  type        = bool
  default     = true
  description = "Whether the gateway Postgres cluster should be provisioned right now. Flipped by the scheduled wake/sleep workflows."
}
