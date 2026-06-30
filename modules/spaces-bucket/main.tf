terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.36.0, < 3.0"
    }
  }
}

resource "digitalocean_spaces_bucket" "main" {
  name   = local.bucket_name
  region = var.region
  acl    = var.acl

  force_destroy = var.force_destroy
}

resource "digitalocean_spaces_key" "this" {
  name = "${local.bucket_name}-key"

  grant {
    bucket     = digitalocean_spaces_bucket.main.name
    permission = var.access_key_permission
  }
}
