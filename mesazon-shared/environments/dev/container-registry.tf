module "registry" {
  source = "../../../modules/container-registry"

  registry_name     = "mesazons-dev"
  subscription_tier = "basic"
  region            = "fra1"
  project_id        = var.project_id
}
