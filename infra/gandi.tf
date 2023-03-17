locals {
  dnssec_key  = "pYOdKjQ9UAyXvBNxvppvsathBVNga1bQ8wYiIrWC3CQ="
  hosts       = merge(module.vultr, module.hcloud)
  nameservers = { for k, v in local.hosts : k => v if contains(v.tags, "nameserver") }
  ns          = concat(values(local.nameservers)[*].fqdn)
}

resource "gandi_glue_record" "nichi_link" {
  for_each = local.nameservers
  zone     = "nichi.link"
  name     = each.key
  ips      = sort([each.value.ipv4, cidrhost("${each.value.ipv6}/128", 0)])
}

resource "gandi_dnssec_key" "nichi_link" {
  domain     = "nichi.link"
  algorithm  = 15
  type       = "ksk"
  public_key = local.dnssec_key
}

resource "gandi_nameservers" "nichi_link" {
  domain      = "nichi.link"
  nameservers = local.ns
}

output "nameservers" {
  value = local.ns
}

output "nodes" {
  value = local.hosts
}
