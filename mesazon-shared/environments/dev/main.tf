module "registry" {
  source = "../../../modules/container-registry"

  registry_name     = "mesazon-dev"
  subscription_tier = "basic"
  region            = "fra1"
}
