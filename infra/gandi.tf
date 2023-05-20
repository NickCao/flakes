locals {
  dnssec_key  = "pYOdKjQ9UAyXvBNxvppvsathBVNga1bQ8wYiIrWC3CQ="
  hosts       = merge(module.vultr, module.hcloud)
  nameservers = { for k, v in local.hosts : k => v if contains(v.tags, "nameserver") }
  ns          = concat(values(local.nameservers)[*].fqdn)
}

output "nameservers" {
  value = local.ns
}

output "nodes" {
  value = local.hosts
}
