variable "hostname" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "region" {
  type = string
}

variable "plan" {
  type = string
}

variable "tags" {
  type = list(string)
}

variable "script" {
  type = string
}

variable "prefix" {
  type = string
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
  plan             = var.plan
  # os_id            = 159
  script_id        = var.script
  enable_ipv6      = true
  activation_email = false
  ddos_protection  = false
  hostname         = var.fqdn
  tags             = var.tags
  label            = var.hostname
  lifecycle {
    ignore_changes = [
      script_id,
    ]
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

data "vultr_region" "region" {
  filter {
    name   = "id"
    values = [vultr_instance.server.region]
  }
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

output "tags" {
  value = var.tags
}

output "prefix" {
  value = var.prefix
}

output "remarks" {
  value = {
    continent = data.vultr_region.region.continent
    country   = data.vultr_region.region.country
    city      = data.vultr_region.region.city
  }
}
