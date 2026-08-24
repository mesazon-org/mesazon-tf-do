terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# NOTE: Unlike every other module in this repository, the zone name is NOT
# composed from a raw name plus region and environment. A DNS zone name is a
# real, globally unique DNS name, so it is passed through verbatim. See the
# naming section of CLAUDE.md.
resource "digitalocean_domain" "main" {
  name = var.domain_name

  lifecycle {
    prevent_destroy = true
  }
}
