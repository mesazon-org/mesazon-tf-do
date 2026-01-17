resource "digitalocean_project" "mesazon_dev" {
  name        = "Mesazon Dev"
  description = "Development environment for Mesazon"
  purpose     = "Testing environment for Mesazon"
  environment = "Development"
}