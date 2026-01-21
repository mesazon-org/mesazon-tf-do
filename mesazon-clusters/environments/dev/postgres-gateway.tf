module "gateway_pg_configure" {
  source = "../../../modules/postgres-configure"

  cluster_id = module.gateway_pg_cluster.cluster_id

  host     = module.gateway_pg_cluster.host
  port     = module.gateway_pg_cluster.port
  username = module.gateway_pg_cluster.username
  password = module.gateway_pg_cluster.password

  database = module.gateway_pg_cluster.database

  user   = "gateway"
  schema = "gateway"
}
