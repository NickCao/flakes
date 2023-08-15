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

variable "userdata" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = list(string)
}

terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
  }
}

resource "vultr_startup_script" "script" {
  name = var.hostname
  type = "pxe"
  script = base64encode(<<EOT
  #!ipxe
  set cmdline sshkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
  chain https://github.com/NickCao/netboot/releases/download/latest/ipxe
  EOT
  )
}

resource "vultr_instance" "server" {
  region           = var.region
  plan             = var.plan
  os_id            = 159
  script_id        = vultr_startup_script.script.id
  user_data        = var.userdata
  enable_ipv6      = true
  activation_email = false
  ddos_protection  = false
  hostname         = var.fqdn
  label            = var.hostname
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

output "tags" {
  value = var.tags
}
