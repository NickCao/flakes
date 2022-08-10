locals {
  nodes = {
    nrt0 = {
      region = "nrt"
    }
    sin0 = {
      region = "sgp"
    }
    sea0 = {
      region = "sea"
    }
  }
}

module "nodes" {
  source   = "./modules/node"
  for_each = local.nodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
  userdata = local.secrets.nixos.key
}

output "nodes" {
  value = module.nodes
}
