locals {
  database             = "${var.database_raw}_${var.cluster_region}_${var.environment}"
  cluster_name         = "${var.cluster_name_raw}-${var.cluster_region}-${var.environment}"
  connection_pool_name = "${var.cluster_name_raw}-pool-01-${var.cluster_region}-${var.environment}"
  vpc_name             = "${var.vpc_name_raw}-${var.cluster_region}-${var.environment}"
  common_tags          = [var.environment, data.digitalocean_project.project.name]
}
