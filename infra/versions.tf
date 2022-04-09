terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    sops = {
      source = "carlpett/sops"
    }
    gandi = {
      source = "go-gandi/gandi"
    }
  }
}
