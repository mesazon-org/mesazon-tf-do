output "name" {
  value = digitalocean_spaces_bucket.main.name
}

output "domain_name" {
  value = digitalocean_spaces_bucket.main.bucket_domain_name
}

output "endpoint" {
  value = digitalocean_spaces_bucket.main.endpoint
}
