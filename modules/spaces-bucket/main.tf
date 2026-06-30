terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_spaces_bucket" "main" {
  name   = local.bucket_name
  region = var.region
  acl    = var.acl

  force_destroy = var.force_destroy
}
