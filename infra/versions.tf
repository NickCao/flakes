terraform {
  backend "http" {
    address = "http://127.0.0.1:5000"
  }
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    sops = {
      source = "carlpett/sops"
    }
    hydra = {
      source = "DeterminateSystems/hydra"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}
