terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

data "digitalocean_project" "project" {
  id = var.project_id
}

# NOTE: This data source assumes the VPC already exists, typically created
# in a separate Terraform workspace (e.g., mesazon-vpc/<env>). If the VPC
# has not been created yet, this lookup will fail on first apply. Ensure
# the VPC workspace is applied before this module is applied.
data "digitalocean_vpc" "vpc" {
  name = local.vpc_name
}

resource "digitalocean_database_cluster" "pg_cluster" {
  count = var.cluster_enabled ? 1 : 0

  project_id = var.project_id

  name       = local.cluster_name
  engine     = "pg"
  version    = var.cluster_version
  size       = var.cluster_size
  region     = var.cluster_region
  node_count = var.cluster_node_count
  tags       = local.common_tags

  private_network_uuid = data.digitalocean_vpc.vpc.id

  # NOTE: no prevent_destroy here on purpose - this cluster is torn down and
  # recreated on a schedule (see cluster_enabled) so it can only be
  # provisioned during its active hours. Data does not persist across a
  # sleep/wake cycle.
}

resource "digitalocean_database_db" "pg_db" {
  count = var.cluster_enabled ? 1 : 0

  cluster_id = digitalocean_database_cluster.pg_cluster[0].id
  name       = local.database

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_connection_pool" "pg_pool" {
  count = var.cluster_enabled ? 1 : 0

  cluster_id = digitalocean_database_cluster.pg_cluster[0].id
  name       = local.connection_pool_name
  mode       = var.connection_pool_mode
  size       = var.connection_pool_size
  db_name    = digitalocean_database_db.pg_db[0].name
  user       = digitalocean_database_cluster.pg_cluster[0].user

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_postgresql_config" "pg_config" {
  count = var.cluster_enabled ? 1 : 0

  cluster_id                          = digitalocean_database_cluster.pg_cluster[0].id
  timezone                            = var.timezone
  idle_in_transaction_session_timeout = var.idle_in_transaction_session_timeout
  log_min_duration_statement          = var.log_min_duration_statement

  depends_on = [digitalocean_database_cluster.pg_cluster]
}
