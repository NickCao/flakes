variable "hostname" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "region" {
  type = string
}

variable "snapshot" {
  type = string
}

variable "userdata" {
  type      = string
  sensitive = true
}

terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
  }
}

resource "vultr_instance" "server" {
  region           = var.region
  plan             = "vc2-1c-1gb"
  snapshot_id      = var.snapshot
  user_data        = var.userdata
  enable_ipv6      = true
  activation_email = false
  ddos_protection  = false
  hostname         = var.fqdn
  label            = var.hostname
  lifecycle {
    create_before_destroy = true
  }
}

resource "vultr_reverse_ipv4" "reverse_ipv4" {
  instance_id = vultr_instance.server.id
  ip          = vultr_instance.server.main_ip
  reverse     = var.fqdn
}

resource "vultr_reverse_ipv6" "reverse_ipv6" {
  instance_id = vultr_instance.server.id
  ip          = vultr_instance.server.v6_main_ip
  reverse     = var.fqdn
}

output "ipv4" {
  value = vultr_reverse_ipv4.reverse_ipv4.ip
}

output "ipv6" {
  value = vultr_reverse_ipv6.reverse_ipv6.ip
}

output "fqdn" {
  value = var.fqdn
}
