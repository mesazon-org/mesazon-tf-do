variable "project_id" {
  type        = string
  description = "DigitalOcean Project ID assignment."
}

variable "environment" {
  type        = string
  description = "Environment name for tagging (dev, prod)."
}

variable "cluster_name_raw" {
  type        = string
  description = "Cluster name in DigitalOcean dashboard."
}

variable "database_raw" {
  type        = string
  description = "Logical database name used in connection strings."
}

variable "cluster_size" {
  type        = string
  default     = "db-s-1vcpu-1gb"
  description = "Droplet size slug (e.g., db-s-1vcpu-1gb)."
}

variable "cluster_version" {
  type        = string
  default     = "18"
  description = "PostgreSQL major version (e.g., 18, 17, 16)."
}

variable "cluster_node_count" {
  type        = number
  default     = 1
  description = "Number of nodes (1 for cheapest, 2 for HA)."
}

variable "cluster_region" {
  type        = string
  description = "DigitalOcean region slug (e.g., nyc1)."
}

variable "connection_pool_mode" {
  type        = string
  default     = "transaction"
  description = "PgBouncer pool mode (session, transaction, statement)."
}

variable "connection_pool_size" {
  type        = number
  default     = 10
  description = "Max concurrent connections in the pool."
}

variable "timezone" {
  type        = string
  default     = "UTC"
  description = "PostgreSQL server timezone."
}

variable "idle_in_transaction_session_timeout" {
  type        = string
  default     = "60000"
  description = "Idle transaction timeout in ms."
}

variable "log_min_duration_statement" {
  type        = string
  default     = "1000"
  description = "Slow query log threshold in ms."
}

variable "vpc_name_raw" {
  description = "The raw name for the VPC, which will be combined with the environment and region to create the final name."
  type        = string
}
