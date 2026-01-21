resource "digitalocean_project" "mesazon_dev" {
  name        = "mesazon-dev"
  description = "Development environment for Mesazon"
  purpose     = "Testing environment for Mesazon"
  environment = "Development"
}