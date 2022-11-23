locals {
  nodes = {
    nrt0 = {
      region     = "nrt"
      nameserver = true
    }
    sin0 = {
      region     = "sgp"
      nameserver = true
    }
    sea0 = {
      region     = "sea"
      nameserver = true
    }
    lax0 = {
      region     = "lax"
      nameserver = false
    }
  }
}

module "nodes" {
  source     = "./modules/node"
  for_each   = local.nodes
  hostname   = each.key
  fqdn       = "${each.key}.nichi.link"
  region     = each.value.region
  userdata   = local.secrets.nixos.key
  nameserver = each.value.nameserver
}
