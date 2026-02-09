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

data "digitalocean_database_cluster" "postgres_cluster" {
  name = local.cluster_name
}

data "digitalocean_vpc" "vpc" {
  name = local.vpc_name
}

resource "digitalocean_database_firewall" "pg_firewall" {
  cluster_id = data.digitalocean_database_cluster.postgres_cluster.id

  dynamic "rule" {
    for_each = local.active_database_firewall_rules
    content {
      type  = rule.value.type
      value = rule.value.value
    }
  }
}

provider "postgresql" {
  host            = data.digitalocean_database_cluster.postgres_cluster.host
  port            = data.digitalocean_database_cluster.postgres_cluster.port
  database        = local.database
  username        = data.digitalocean_database_cluster.postgres_cluster.user
  password        = data.digitalocean_database_cluster.postgres_cluster.password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}

resource "postgresql_schema" "database_schema" {
  name          = local.schema
  owner         = postgresql_role.user_group.name
  if_not_exists = true
}

// Provided user & group
resource "digitalocean_database_user" "database_user" {
  cluster_id = data.digitalocean_database_cluster.postgres_cluster.id
  name       = local.user
}

resource "postgresql_role" "user_group" {
  name  = local.user_group
  login = false
}

// Flyway user & group
resource "digitalocean_database_user" "flyway_user" {
  cluster_id = data.digitalocean_database_cluster.postgres_cluster.id
  name       = local.flyway_user
}

resource "postgresql_role" "flyway_group" {
  name  = local.flyway_group
  login = false
}

// !!IMPORTANT: every resource create below should depend on the previous run in single order and avoid deadlocks!
resource "postgresql_grant_role" "user_assignment" {
  role       = digitalocean_database_user.database_user.name
  grant_role = postgresql_role.user_group.name

  depends_on = [postgresql_role.flyway_group]
}

resource "postgresql_grant_role" "flyway_assignment" {
  role       = digitalocean_database_user.flyway_user.name
  grant_role = postgresql_role.flyway_group.name

  depends_on = [postgresql_grant_role.user_assignment]
}

resource "postgresql_grant" "user_provided_schema_usage" {
  role        = postgresql_role.user_group.name
  database    = local.database
  schema      = postgresql_schema.database_schema.name
  object_type = "schema"
  privileges  = ["USAGE"]

  depends_on = [postgresql_grant_role.flyway_assignment]
}

resource "postgresql_grant" "flyway_provided_schema_usage" {
  role        = postgresql_role.flyway_group.name
  database    = local.database
  schema      = postgresql_schema.database_schema.name
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [postgresql_grant.user_provided_schema_usage]
}

resource "postgresql_grant" "flyway_public_schema_usage" {
  role        = postgresql_role.flyway_group.name
  database    = local.database
  schema      = "public"
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]

  depends_on = [postgresql_grant.flyway_provided_schema_usage]
}

resource "postgresql_default_privileges" "flyway_sequences_to_user" {
  role        = postgresql_role.user_group.name
  database    = local.database
  schema      = postgresql_schema.database_schema.name
  owner       = digitalocean_database_user.flyway_user.name
  object_type = "sequence"
  privileges  = ["USAGE"]

  depends_on = [postgresql_grant.flyway_public_schema_usage]
}

resource "postgresql_default_privileges" "flyway_tables_to_user" {
  role        = postgresql_role.user_group.name
  database    = local.database
  schema      = postgresql_schema.database_schema.name
  owner       = digitalocean_database_user.flyway_user.name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  depends_on = [postgresql_default_privileges.flyway_sequences_to_user]
}
