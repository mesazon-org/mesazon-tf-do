module "mesazon-droplet" {
  source = "../../../modules/droplet"

  project_id = var.project_id
  environment = var.environment

  name   = "mesazon"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-24-04-x64"

  team_members = {
    "arigas" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKADdYc4+7AzoskrlMIfQ+EKFzAPI0PZY0iilYci6Qgnh/oQX+1GFw3bPJOUH6G88Kgm8chn0A14yEZwL1fzdjw9JftnMknCpkowAUqhpgLNqOlxRMFF/vgZLlFRnjJIy/RIYAIN8UTXtEzOtlW8mAfE+HidEAWeLxZb72UH828Jw5xVUW84+Gbni5Z1ZmrpoW1rGNomtI7Ws0zYnwG7hfDC3719cCV6lKO1yoiOeUUoo1pe3pLtd+wGd9ebTVD6sioJwcISZdtu+ZxYoCsCjIKYOlF1en0WL77zktojfg7hYWSxee/wWVzzBCykJGmNhJxYpcwgvXQ862bULOl2SOvi1DcS3SknO4m4ANACGPKMiusLDytvaZKDcsctKAYYXtOuYi7cVnJRwpmQFQsORamyC6oO1cfyATyWhhF3jKnyxMpfZQxFgEumFPyIceEH4wytuHkwM8WZSYiXXsQu3vIjBrsQ3xcqtxrydhTFKvbetffzgEYX/bzHNC0hyXZTyx8woxRDrP1g5Qcw8SAd0Y8DhkFz3D2Nn00QCPJggGRMiEyU44JSxqARYn/WSBGwzY7TV5b6fVo1da6Cf7NAYohkYh7/opPTYwFcd5NXRqcc3vtckYWMG5OCaTk/VydttXawK4oik7m2PFsdQvvZcEEcVaIRUzrUTTCXC+vF/CwQ== arigas@mesazon"
  }
}
