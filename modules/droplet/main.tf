terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_ssh_key" "team" {
  for_each   = var.team_members
  name       = each.key
  public_key = each.value
}

resource "digitalocean_droplet" "web" {
  name   = "${var.name}-${var.region}-${var.environment}"
  image  = var.image
  region = var.region
  size   = var.size

  ssh_keys = [for k in digitalocean_ssh_key.team : k.fingerprint]
}

resource "digitalocean_project_resources" "barfoo" {
  project = var.project_id
  resources = [
    digitalocean_droplet.web.urn
  ]
}