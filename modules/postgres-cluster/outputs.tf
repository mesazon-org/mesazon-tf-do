output "cluster_id" {
  value = one(digitalocean_database_cluster.pg_cluster[*].id)
}

output "host" {
  value = one(digitalocean_database_cluster.pg_cluster[*].host)
}

output "port" {
  value = one(digitalocean_database_cluster.pg_cluster[*].port)
}

output "user" {
  value = one(digitalocean_database_cluster.pg_cluster[*].user)
}

output "password" {
  value     = one(digitalocean_database_cluster.pg_cluster[*].password)
  sensitive = true
}

output "database" {
  value = one(digitalocean_database_db.pg_db[*].name)
}
