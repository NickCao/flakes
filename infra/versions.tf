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
    minio = {
      source = "aminueza/minio"
    }
    gandi = {
      source = "go-gandi/gandi"
    }
  }
}
