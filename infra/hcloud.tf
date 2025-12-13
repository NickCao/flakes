locals {
  hnodes = {
    iad0 = {
      datacenter = "ash-dc1"
      plan       = "cpx11"
      tags       = ["hetzner", "nameserver"]
    }
    iad1 = {
      datacenter = "ash-dc1"
      plan       = "cpx11"
      tags       = ["hetzner"]
    }
    hio0 = {
      datacenter = "hil-dc1"
      plan       = "cpx31"
      tags       = ["hetzner"]
    }
    hel0 = {
      datacenter = "hel1-dc2"
      plan       = "cx23"
      tags       = ["hetzner"]
    }
    hel1 = {
      datacenter = "hel1-dc2"
      plan       = "cx23"
      tags       = ["hetzner"]
    }
  }
}

module "hcloud" {
  source     = "./modules/hcloud"
  for_each   = local.hnodes
  hostname   = each.key
  fqdn       = "${each.key}.nichi.link"
  datacenter = each.value.datacenter
  plan       = each.value.plan
  tags       = each.value.tags
}
