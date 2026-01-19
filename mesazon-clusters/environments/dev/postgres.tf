module "gateway_pg_cluster" {
  source = "../../../modules/postgresql"

  project_id  = var.project_id
  environment = var.environment

  cluster_name       = "gateway-dev"
  cluster_size       = "db-s-1vcpu-1gb"
  cluster_region     = "fra1"
  cluster_node_count = 1

  database = "gateway_db"
}

module "gateway_pg_configure" {
  source = "../../../modules/postresql-configure"

  cluster_id = module.gateway_pg_cluster.cluster_id
  host       = module.gateway_pg_cluster.host
  port       = module.gateway_pg_cluster.port
  username   = module.gateway_pg_cluster.username
  password   = module.gateway_pg_cluster.password
  database   = module.gateway_pg_cluster.database
}