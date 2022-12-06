locals {
  nodes = {
    nrt0 = {
      region = "nrt"
      tags   = ["vultr", "nameserver"]
    }
    sin0 = {
      region = "sgp"
      tags   = ["vultr", "nameserver"]
    }
    sea0 = {
      region = "sea"
      tags   = ["vultr", "nameserver"]
    }
    lax0 = {
      region = "lax"
      tags   = ["vultr"]
    }
  }
}

module "vultr" {
  source   = "./modules/vultr"
  for_each = local.nodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
  userdata = local.secrets.nixos.key
  tags     = each.value.tags
}
