module "gateway_organization_media_bucket" {
  source = "../../modules/spaces-bucket"

  environment = local.environment
  region      = local.region

  bucket_name_raw = "gateway-organization-media"
  acl             = "public-read"
}
