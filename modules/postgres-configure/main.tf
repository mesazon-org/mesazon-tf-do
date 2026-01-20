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
  host            = var.host
  port            = var.port
  database        = "defaultdb" # Connect to default to manage roles
  username        = var.username
  password        = var.password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}

resource "digitalocean_database_user" "database_user" {
  cluster_id = var.cluster_id
  name       = var.user
}

resource "postgresql_role" "user_group" {
  name  = "${var.user}_group"
  login = false
}

resource "postgresql_grant" "flyway_schema_usage" {
  role        = postgresql_role.user_group.name
  database    = var.database_name
  schema      = var.schema_name
  object_type = "schema"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant_role" "user_assignment" {
  role       = digitalocean_database_user.database_user.name
  grant_role = postgresql_role.user_group.name
}
