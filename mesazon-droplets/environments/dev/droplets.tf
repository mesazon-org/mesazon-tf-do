module "mesazon-droplet" {
  source = "../../../modules/droplet"

  project_id  = var.project_id
  do_ssh_private_key  = var.do_ssh_private_key
  environment = var.environment

  name   = "mesazon"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"

  team_members = {
    "arigas" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoCXDl1/WEpb/kH8UJ4A1zXVQpSIgCjMPnqeJkTRsER arigas@masazon"
    "github" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS0XkcOjWhbKwr3cvuYDaqX4hqMj1dB0W9oSwZjTD0x github@masazon"
  }
}
