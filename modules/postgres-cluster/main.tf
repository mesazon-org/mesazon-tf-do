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

resource "digitalocean_database_cluster" "pg_cluster" {
  project_id = var.project_id

  name       = local.cluster_name
  engine     = "pg"
  version    = var.cluster_version
  size       = var.cluster_size
  region     = var.cluster_region
  node_count = var.cluster_node_count
  tags       = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_database_db" "pg_db" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id
  name       = local.database

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_connection_pool" "pg_pool" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id
  name       = local.connection_pool_name
  mode       = var.connection_pool_mode
  size       = var.connection_pool_size
  db_name    = digitalocean_database_db.pg_db.name
  user       = digitalocean_database_cluster.pg_cluster.user

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_postgresql_config" "pg_config" {
  cluster_id                          = digitalocean_database_cluster.pg_cluster.id
  timezone                            = var.timezone
  idle_in_transaction_session_timeout = var.idle_in_transaction_session_timeout
  log_min_duration_statement          = var.log_min_duration_statement

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_firewall" "block_all" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id

  rule {
    type  = "ip_addr"
    value = "127.0.0.1"
  }
}
