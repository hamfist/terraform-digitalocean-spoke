output "loadbalancer_ip" {
  value = digitalocean_loadbalancer.app.ip
}

output "droplet_urn" {
  value = digitalocean_droplet.app.urn
}

output "loadbalancer_urn" {
  value = digitalocean_loadbalancer.app.urn
}

output "database_cluster_urn" {
  value = digitalocean_database_cluster.pg.urn
}

output "droplet_ipv4_address" {
  value = digitalocean_droplet.app.ipv4_address
}
