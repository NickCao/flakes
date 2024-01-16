locals {
  hnodes = {
    iad0 = {
      region = "ash-dc1"
      plan   = "cpx11"
      tags   = ["hetzner", "nameserver"]
    }
    hio0 = {
      region = "hil-dc1"
      plan   = "cpx31"
      tags   = ["hetzner"]
    }
  }
}

module "hcloud" {
  source   = "./modules/hcloud"
  for_each = local.hnodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
  plan     = each.value.plan
  tags     = each.value.tags
}

resource "hcloud_volume" "data" {
  name              = "data"
  size              = 128
  location          = "hil"
  delete_protection = true
}

resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.data.id
  server_id = module.hcloud["hio0"].id
}
