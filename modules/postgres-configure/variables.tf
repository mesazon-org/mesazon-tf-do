variable "runner_ip" {
  description = "GitHub runner IP address to allow in the cluster firewall"
  type        = string
}

variable "environment" {
  type        = string
  description = "The environment for which to configure the database."
}

variable "region" {
  type        = string
  description = "DigitalOcean region slug (e.g., nyc1)."
}

variable "cluster_name_raw" {
  type        = string
  description = "Cluster name in DigitalOcean dashboard."
}

variable "database_raw" {
  type        = string
  description = "Logical database name used in connection strings."
}

variable "user_raw" {
  type        = string
  description = "Database user to create."
}

variable "schema_raw" {
  type        = string
  description = "Schema name to create."
}

variable "disable_runner_ip" {
  description = "Whether to disable the runner IP in the firewall rules."
  type        = bool
  default     = false
}
