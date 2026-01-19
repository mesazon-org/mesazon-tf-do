variable "cluster_id" {
  type        = string
  description = "Cluster name in DigitalOcean dashboard."
}

variable "host" {
  type        = string
  description = "Database host."
}

variable "port" {
  type        = number
  description = "Database port."
  default     = 25060
}

variable "username" {
  type        = string
  description = "Database user to create."
}

variable "password" {
  type        = string
  description = "Database user password."
  sensitive   = true
}

variable "database" {
  type        = string
  description = "Database name to create."
}
