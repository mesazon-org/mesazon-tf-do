module "mesaon-registry" {
  source = "../../../modules/container-registry"

  registry_name     = "mesazon"
  subscription_tier = "basic"
  region            = "fra1"
}