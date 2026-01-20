terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21.0"
    }
  }
}

provider "postgresql" {
  host            = digitalocean_database_cluster.pg_cluster.host
  port            = digitalocean_database_cluster.pg_cluster.host
  database        = var.database
  username        = digitalocean_database_cluster.pg_cluster.user
  password        = digitalocean_database_cluster.pg_cluster.password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}

resource "digitalocean_database_cluster" "pg_cluster" {
  name       = "${var.cluster_name}-${var.environment}-${var.cluster_region}"
  engine     = "pg"
  version    = var.cluster_version
  size       = var.cluster_size
  region     = var.cluster_region
  node_count = var.cluster_node_count
  tags       = [var.environment]
  project_id = var.project_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_database_db" "pg_db" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id
  name       = var.database

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "digitalocean_database_connection_pool" "pg_pool" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id
  name       = "${var.cluster_name}-pool-01"
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

resource "digitalocean_database_user" "flyway_user" {
  cluster_id = digitalocean_database_cluster.pg_cluster.id
  name       = "flyway_user"

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "postgresql_role" "flyway_group" {
  name  = "flyway_group"
  login = false

  depends_on = [digitalocean_database_cluster.pg_cluster]
}

resource "postgresql_grant" "flyway_schema_usage" {
  role        = postgresql_role.flyway_group.name
  database    = var.database
  schema      = "public"
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [digitalocean_database_user.flyway_user]
}

resource "postgresql_grant_role" "flyway_assignment" {
  role       = digitalocean_database_user.flyway_user.name
  grant_role = postgresql_role.flyway_group.name

  depends_on = [digitalocean_database_user.flyway_user, postgresql_role.flyway_group]
}
