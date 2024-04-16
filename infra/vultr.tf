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
    ewr0 = {
      region = "ewr"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
    }
    lax0 = {
      region = "lax"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
    }
    itm0 = {
      region = "itm"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
    }
    fra0 = {
      region = "fra"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
    }
    lhr0 = {
      region = "lhr"
      plan   = "vhp-1c-1gb-amd"
      tags   = ["vultr"]
    }
  }
}

resource "vultr_startup_script" "script" {
  name = "nixos"
  type = "pxe"
  script = base64encode(<<EOT
  #!ipxe
  set cmdline sshkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
  chain https://github.com/NickCao/netboot/releases/download/latest/ipxe
  EOT
  )
}

module "vultr" {
  source   = "./modules/vultr"
  for_each = local.nodes
  hostname = each.key
  fqdn     = "${each.key}.nichi.link"
  region   = each.value.region
  plan     = each.value.plan
  tags     = each.value.tags
  script   = vultr_startup_script.script.id
}
