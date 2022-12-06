locals {
  hnodes = {
    iad0 = {
      region = "ash-dc1"
    }
  }
}

module "hcloud" {
  source   = "./modules/hcloud"
  for_each = local.hnodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
}
