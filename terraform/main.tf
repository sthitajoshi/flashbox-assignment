# One droplet per environment (prod, staging) so staging can never affect prod.
resource "digitalocean_droplet" "app" {
  for_each  = var.environments
  name      = "${var.project_name}-${each.key}"
  region    = var.do_region
  size      = var.droplet_size
  image     = "ubuntu-24-04-x64"
  ssh_keys  = [var.ssh_key_fingerprint]
  user_data = <<-CLOUD
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose-v2
      - curl
    runcmd:
      - [ sh, -c, "systemctl enable --now docker" ]
      - [ sh, -c, "mkdir -p /opt/flashbox && chown -R 1000:1000 /opt/flashbox" ]
  CLOUD
  tags      = ["flashbox", each.key]
}

resource "digitalocean_firewall" "app" {
  name        = "${var.project_name}-firewall"
  droplet_ids = [for droplet in digitalocean_droplet.app : droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
