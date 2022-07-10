locals {
  dnssec_key = "LBbl0S/D5U9yKQOy+r0+lZEJP3kpPklCBagsT13p64U="
  nameservers = values(module.nodes)[*].fqdn
}

resource "gandi_glue_record" "nichi_link" {
  for_each = local.nodes
  zone     = "nichi.link"
  name     = each.key
  ips      = sort([module.nodes[each.key].ipv4, cidrhost("${module.nodes[each.key].ipv6}/128", 0)])
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
  nameservers = local.nameservers
}

resource "gandi_nameservers" "nichi_co" {
  domain      = "nichi.co"
  nameservers = local.nameservers
}

resource "gandi_nameservers" "scp_link" {
  domain      = "scp.link"
  nameservers = local.nameservers
}

output "nameservers" {
  value = local.nameservers
}
