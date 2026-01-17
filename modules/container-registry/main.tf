terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_container_registry" "main" {
  name                   = var.registry_name
  subscription_tier_slug = var.subscription_tier
  region                 = var.region
}

resource "digitalocean_project_resources" "resources" {
  project = var.project_id
  resources = [
    digitalocean_container_registry.main.urn
  ]
}