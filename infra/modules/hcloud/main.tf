variable "hostname" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "location" {
  type = string
}

variable "plan" {
  type = string
}

variable "tags" {
  type = list(string)
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
  server_type        = var.plan
  location           = var.location
  image              = "debian-11"
  labels             = { for tag in var.tags : tag => "" }
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
  location          = var.location
  assignee_type     = "server"
  auto_delete       = false
  delete_protection = true
}

resource "hcloud_primary_ip" "ipv6" {
  name              = "${var.hostname}-v6"
  type              = "ipv6"
  location          = var.location
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

data "hcloud_location" "location" {
  name = var.location
}

output "id" {
  value = hcloud_server.server.id
}

output "ipv4" {
  value = hcloud_primary_ip.ipv4.ip_address
}

output "ipv6" {
  value = cidrhost(hcloud_primary_ip.ipv6.ip_network, 1)
}

output "fqdn" {
  value = var.fqdn
}

output "tags" {
  value = var.tags
}

output "remarks" {
  value = {
    // continent = data.hcloud_location.location.continent
    country = data.hcloud_location.location.country
    city    = data.hcloud_location.location.city
  }
}
