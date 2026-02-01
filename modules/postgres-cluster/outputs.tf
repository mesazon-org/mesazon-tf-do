output "cluster_id" {
  value = digitalocean_database_cluster.pg_cluster.id
}

output "host" {
  value = digitalocean_database_cluster.pg_cluster.host
}

output "port" {
  value = digitalocean_database_cluster.pg_cluster.port
}

output "user" {
  value = digitalocean_database_cluster.pg_cluster.user
}

output "password" {
  value = digitalocean_database_cluster.pg_cluster.password
}

output "database" {
  value = digitalocean_database_db.pg_db.name
}
