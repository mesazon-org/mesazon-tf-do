module "gateway-vpc" {
  source       = "../../modules/vpc"
  environment  = local.environment
  region       = local.region
  vpc_name_raw = "gateway-vpc"
  ip_range     = "10.10.10.0/24"
}
