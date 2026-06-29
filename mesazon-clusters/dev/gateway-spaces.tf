module "gateway_logos_bucket" {
  source = "../../modules/spaces-bucket"

  environment = local.environment
  region      = local.region

  bucket_name_raw = "gateway-logos"
  acl             = "public-read"
}
