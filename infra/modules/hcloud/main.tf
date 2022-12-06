variable "hostname" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "region" {
  type = string
}

terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_server" "server" {
  name               = var.hostname
  server_type        = "cpx11"
  datacenter         = var.region
  image              = "debian-11"
  delete_protection  = true
  rebuild_protection = true
  public_net {
    ipv4 = hcloud_primary_ip.ipv4.id
    ipv6 = hcloud_primary_ip.ipv6.id
  }
}

resource "hcloud_primary_ip" "ipv4" {
  name              = "${var.hostname}-v4"
  type              = "ipv4"
  datacenter        = var.region
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_primary_ip" "ipv6" {
  name              = "${var.hostname}-v6"
  type              = "ipv6"
  datacenter        = var.region
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_rdns" "ipv4" {
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv4_address
  dns_ptr    = var.fqdn
}

resource "hcloud_rdns" "ipv6" {
  server_id  = hcloud_server.server.id
  ip_address = hcloud_server.server.ipv6_address
  dns_ptr    = var.fqdn
}
