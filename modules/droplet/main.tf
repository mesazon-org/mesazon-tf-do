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

resource "digitalocean_vpc" "web_vpc" {
  name     = "${var.name}-${var.region}-${var.environment}-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_droplet" "web_server" {
  name   = "${var.name}-${var.region}-${var.environment}"
  image  = var.image
  region = var.region
  size   = var.size

  vpc_uuid = digitalocean_vpc.web_vpc.id

  ssh_keys = [for k in digitalocean_ssh_key.team : k.fingerprint]
}

resource "digitalocean_loadbalancer" "public_lb" {
  name     = "${var.name}-${var.region}-${var.environment}-lb"
  region   = var.region
  vpc_uuid = digitalocean_vpc.web_vpc.id

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  droplet_ids = [digitalocean_droplet.web_server.id]
}

resource "digitalocean_firewall" "web_fw" {
  name = "only-lb-and-ssh"

  droplet_ids = [digitalocean_droplet.web_server.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow HTTP traffic ONLY from the Load Balancer (Private Network)
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.public_lb.id]
  }

  # Standard outbound rules (required for updates/docker pulls)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_project_resources" "project_resources" {
  project = var.project_id
  resources = [
    digitalocean_droplet.web_server.urn
  ]
}
