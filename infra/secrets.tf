data "sops_file" "secrets" {
  source_file = "secrets.yaml"
}

locals {
  secrets = yamldecode(data.sops_file.secrets.raw)
}

provider "vultr" {
  api_key = local.secrets.vultr.api_key
}

provider "hydra" {
  host     = "https://hydra.nichi.co"
  username = "terraform"
  password = local.secrets.hydra.password
}

provider "hcloud" {
  token = local.secrets.hcloud.token
}

provider "keycloak" {
  client_id     = "terraform"
  client_secret = local.secrets.keycloak.token
  realm         = "nichi"
  url           = "https://id.nichi.co"
}
