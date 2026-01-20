module "gateway_pg_cluster" {
  source = "../../../modules/postgres-cluster"

  project_id  = var.project_id
  environment = var.environment

  cluster_name       = "gateway"
  cluster_size       = "db-s-1vcpu-1gb"
  cluster_region     = "fra1"
  cluster_node_count = 1

  database = "gateway_db"
}
