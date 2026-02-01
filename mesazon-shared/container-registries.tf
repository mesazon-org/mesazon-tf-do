module "mesazon-registry" {
  source = "../modules/container-registry"

  registry_name_raw = "mesazon"
  subscription_tier = "basic"
  region            = local.region
}
