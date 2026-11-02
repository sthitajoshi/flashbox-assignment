output "droplet_ips" {
  value = { for env, droplet in digitalocean_droplet.app : env => droplet.ipv4_address }
}

output "droplet_ids" {
  value = { for env, droplet in digitalocean_droplet.app : env => droplet.id }
}
