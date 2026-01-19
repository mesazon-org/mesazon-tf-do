output "cluster_id" {
  value = digitalocean_database_cluster.mesazon_dev_pg_cluster.id
}

output "host" {
  value = digitalocean_database_cluster.mesazon_dev_pg_cluster.host
}

output "port" {
  value = digitalocean_database_cluster.mesazon_dev_pg_cluster.port
}

output "username" {
  value = "doadmin"
}

output "password" {
  value = digitalocean_database_cluster.mesazon_dev_pg_cluster.password
}
