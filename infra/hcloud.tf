locals {
  hnodes = {
    iad0 = {
      location = "ash"
      plan     = "cpx11"
      tags     = ["hetzner", "nameserver"]
    }
    hio0 = {
      location = "hil"
      plan     = "cpx31"
      tags     = ["hetzner"]
    }
    hel0 = {
      location = "hel1"
      plan     = "cx23"
      tags     = ["hetzner"]
    }
    hel1 = {
      location = "hel1"
      plan     = "cx23"
      tags     = ["hetzner"]
    }
  }
}

module "hcloud" {
  source   = "./modules/hcloud"
  for_each = local.hnodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  location = each.value.location
  plan     = each.value.plan
  tags     = each.value.tags
}

resource "hcloud_zone" "nichi_link" {
  name = "nichi.link"
  mode = "secondary"

  primary_nameservers = [
    {
      address        = module.hcloud["iad0"].ipv4
      tsig_algorithm = "hmac-sha256"
      tsig_key       = local.secrets.hcloud.tsig
    }
  ]

  delete_protection = true
}

output "secondary_nameservers" {
  value = hcloud_zone.nichi_link.authoritative_nameservers.assigned
}
