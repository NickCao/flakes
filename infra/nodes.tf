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
  hostname = "${each.key}.nichi.link"
  region   = each.value.region
  snapshot = "42a38945-8421-4b49-a06d-15c9db72f75a"
  userdata = local.secrets.nixos.key
}

output "nodes" {
  value = module.nodes
}
