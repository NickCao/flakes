ephemeral "sops_file" "secrets" {
  source_file = "${path.module}/secrets.yaml"
}

locals {
  secrets = yamldecode(ephemeral.sops_file.secrets.raw)
}

provider "vultr" {
  api_key = local.secrets.vultr.api_key
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

provider "scaleway" {
  organization_id = local.secrets.scaleway.organization_id
  access_key      = local.secrets.scaleway.access_key
  secret_key      = local.secrets.scaleway.secret_key
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  auth_login_jwt {
    mount = "spiffe"
    role  = "admin"
  }
}
