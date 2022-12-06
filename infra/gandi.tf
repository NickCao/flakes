locals {
  dnssec_key = "LBbl0S/D5U9yKQOy+r0+lZEJP3kpPklCBagsT13p64U="
  hosts = merge(module.vultr, module.hcloud, {
    sin1 = {
      fqdn = "sin1.nichi.link",
      ipv4 = "154.26.139.162",
      ipv6 = "2407:3640:2108:595::1",
      tags = ["contabo"]
    },
  })
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

resource "gandi_dnssec_key" "scp_link" {
  domain     = "scp.link"
  algorithm  = 15
  type       = "ksk"
  public_key = local.dnssec_key
}

resource "gandi_nameservers" "nichi_link" {
  domain      = "nichi.link"
  nameservers = local.ns
}

resource "gandi_nameservers" "nichi_co" {
  domain      = "nichi.co"
  nameservers = local.ns
}

resource "gandi_nameservers" "scp_link" {
  domain      = "scp.link"
  nameservers = local.ns
}

output "nameservers" {
  value = local.ns
}

output "nodes" {
  value = local.hosts
}
