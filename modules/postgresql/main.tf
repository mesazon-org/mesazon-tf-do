terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_database_cluster" "mesazon_dev_pg_cluster" {
  name       = var.cluster_name
  engine     = "pg"
  version    = "18"
  size       = var.cluster_size
  region     = var.cluster_region
  node_count = var.cluster_node_count
  tags       = [var.environment]
  project_id = var.project_id
}

resource "digitalocean_database_db" "app_db" {
  cluster_id = digitalocean_database_cluster.mesazon_dev_pg_cluster.id
  name       = var.database
}

resource "digitalocean_database_connection_pool" "pg_pool" {
  cluster_id = digitalocean_database_cluster.mesazon_dev_pg_cluster.id
  name       = var.cluster_name + "-pool-01"
  mode       = var.connection_pool_mode
  size       = var.connection_pool_size
  db_name    = digitalocean_database_db.app_db.name
  user       = "doadmin"
}

resource "digitalocean_database_postgresql_config" "pg_config" {
  cluster_id                          = digitalocean_database_cluster.mesazon_dev_pg_cluster.id
  timezone                            = var.timezone
  idle_in_transaction_session_timeout = var.idle_in_transaction_session_timeout
  log_min_duration_statement          = var.log_min_duration_statement
}
