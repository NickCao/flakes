locals {
  nodes = {
    nrt0 = {
      region = "nrt"
      plan   = "vc2-1c-1gb"
      tags   = ["vultr", "nameserver"]
      prefix = "786"
    }
    sin0 = {
      region = "sgp"
      plan   = "vc2-1c-1gb"
      tags   = ["vultr", "nameserver"]
      prefix = "f25"
    }
    sea0 = {
      region = "sea"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr", "nameserver"]
      prefix = "4ed"
    }
    ewr0 = {
      region = "ewr"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr", "uefi"]
      prefix = "aeb"
    }
    lax0 = {
      region = "lax"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr", "uefi"]
      prefix = "a2a"
    }
    itm0 = {
      region = "itm"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
      prefix = "a4b"
    }
    fra0 = {
      region = "fra"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
      prefix = "38c"
    }
    lhr0 = {
      region = "lhr"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr", "uefi"]
      prefix = "244"
    }
  }
}

data "vultr_os" "debian" {
  filter {
    name   = "name"
    values = ["Debian 13 x64 (trixie)"]
  }
}

module "vultr" {
  source   = "./modules/vultr"
  for_each = local.nodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
  plan     = each.value.plan
  tags     = each.value.tags
  os       = data.vultr_os.debian.id
  prefix   = each.value.prefix
}
