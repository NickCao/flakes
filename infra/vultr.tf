locals {
  nodes = {
    nrt0 = {
      region = "nrt"
      plan   = "vc2-1c-1gb"
      tags   = ["vultr", "nameserver"]
    }
    sin0 = {
      region = "sgp"
      plan   = "vc2-1c-1gb"
      tags   = ["vultr", "nameserver"]
    }
    sea0 = {
      region = "sea"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr", "nameserver"]
    }
    lax0 = {
      region = "lax"
      plan   = "vc2-1c-1gb"
      tags   = ["vultr"]
    }
    itm0 = {
      region = "itm"
      plan   = "vhp-1c-1gb-amd"
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
  plan     = each.value.plan
  userdata = local.secrets.nixos.key
  tags     = each.value.tags
}
