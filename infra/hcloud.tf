locals {
  hnodes = {
    iad0 = {
      region = "ash-dc1"
      plan   = "cpx11"
    }
    hio0 = {
      region = "hil-dc1"
      plan   = "cpx31"
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
}
