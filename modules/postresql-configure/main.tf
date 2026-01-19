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

resource "digitalocean_database_user" "flyway_user" {
  cluster_id = var.cluster_id
  name       = "flyway_user"
}

resource "postgresql_role" "flyway_group" {
  name  = "flyway_group"
  login = false
}

resource "postgresql_grant" "flyway_schema_usage" {
  role        = postgresql_role.flyway_group.name
  database    = var.database
  schema      = "public"
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]
}

resource "postgresql_grant_role" "flyway_assignment" {
  role       = digitalocean_database_user.flyway_user.name
  grant_role = postgresql_role.flyway_group.name
}
