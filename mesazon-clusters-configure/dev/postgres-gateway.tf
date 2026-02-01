module "gateway_pg_configure" {
  source = "../../modules/postgres-configure"

  runner_ip = var.runner_ip

  cluster_name_raw = "gateway"
  environment      = local.environment
  region           = local.region

  database_raw = "gateway_db"
  user_raw     = "gateway"
  schema_raw   = "gateway"
}
