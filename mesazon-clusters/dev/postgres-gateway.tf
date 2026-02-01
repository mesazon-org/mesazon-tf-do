module "gateway_pg_cluster" {
  source = "../../modules/postgres-cluster"

  project_id  = var.project_id
  environment = local.environment

  cluster_name_raw   = "gateway"
  cluster_size       = "db-s-1vcpu-1gb"
  cluster_region     = local.region
  cluster_node_count = 1

  database_raw = "gateway_db"
}
