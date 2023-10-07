terraform {
  backend "http" {
    address = "http://127.0.0.1:5000"
  }
  required_providers {
    vultr = {
      source = "registry.terraform.io/vultr/vultr"
    }
    sops = {
      source = "registry.terraform.io/carlpett/sops"
    }
    hydra = {
      source = "registry.terraform.io/DeterminateSystems/hydra"
    }
    hcloud = {
      source = "registry.terraform.io/hetznercloud/hcloud"
    }
  }
}
