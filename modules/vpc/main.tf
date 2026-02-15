terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_vpc" "main" {
  name     = local.vpc_name
  region   = var.region
  ip_range = var.ip_range
}
