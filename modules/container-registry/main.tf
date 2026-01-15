terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_container_registry" "main" {
  name                   = var.registry_name + "-" + var.env
  subscription_tier_slug = var.subscription_tier
  region                 = var.region
}
