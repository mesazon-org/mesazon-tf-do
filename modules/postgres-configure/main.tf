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
  database        = var.database
  username        = var.username
  password        = var.password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}

resource "postgresql_schema" "database_schema" {
  name  = var.schema
  owner = var.username
}

resource "digitalocean_database_user" "database_user" {
  cluster_id = var.cluster_id
  name       = var.user
}

resource "postgresql_role" "user_group" {
  name  = "${var.user}_group"
  login = false
}

resource "postgresql_grant" "user_provided_schema_usage" {
  role        = postgresql_role.user_group.name
  database    = var.database
  schema      = postgresql_schema.database_schema.name
  object_type = "schema"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

resource "postgresql_grant_role" "user_assignment" {
  role       = digitalocean_database_user.database_user.name
  grant_role = postgresql_role.user_group.name
}

// Flyway user
resource "digitalocean_database_user" "flyway_user" {
  cluster_id = var.cluster_id
  name       = "${var.user}_flyway_user"
}

resource "postgresql_role" "flyway_group" {
  name  = "${var.user}_flyway_group"
  login = false
}

resource "postgresql_grant" "flyway_provided_schema_usage" {
  role        = postgresql_role.flyway_group.name
  database    = var.database
  schema      = postgresql_schema.database_schema.name
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [digitalocean_database_user.flyway_user]
}

resource "postgresql_grant" "flyway_public_schema_usage" {
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
