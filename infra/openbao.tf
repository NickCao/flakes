resource "vault_mount" "secrets" {
  path    = "secrets"
  type    = "kv"
  options = { version = "2" }
}

resource "vault_kv_secret_v2" "scaleway_cockpit_par" {
  mount = vault_mount.secrets.path
  name  = "scaleway_cockpit_par"
  data_json = jsonencode(
    {
      secret_key = scaleway_cockpit_token.victoriametrics_par.secret_key
      url        = data.scaleway_cockpit_source.metrics_par.url
    }
  )
}

resource "vault_kv_secret_v2" "scaleway_iam_restic" {
  mount = vault_mount.secrets.path
  name  = "scaleway_iam_restic"
  data_json = jsonencode(
    {
      access_key = scaleway_iam_api_key.restic.access_key
      secret_key = scaleway_iam_api_key.restic.secret_key
    }
  )
}

resource "vault_kv_secret_v2" "scaleway_iam_litestream" {
  mount = vault_mount.secrets.path
  name  = "scaleway_iam_litestream"
  data_json = jsonencode(
    {
      access_key = scaleway_iam_api_key.litestream.access_key
      secret_key = scaleway_iam_api_key.litestream.secret_key
    }
  )
}

resource "vault_kv_secret_v2" "oidc_client_rustical" {
  mount = vault_mount.secrets.path
  name  = "oidc_client_rustical"
  data_json = jsonencode(
    {
      client_id     = keycloak_openid_client.rustical.client_id
      client_secret = keycloak_openid_client.rustical.client_secret
    }
  )
}

resource "vault_policy" "restic" {
  name = "restic"

  policy = <<EOT
path "${vault_kv_secret_v2.scaleway_iam_restic.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "restic" {
  role_name       = "restic"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/restic"

  backend = "spiffe"

  token_policies = [vault_policy.restic.name]
}

resource "vault_policy" "litestream" {
  name = "litestream"

  policy = <<EOT
path "${vault_kv_secret_v2.scaleway_iam_litestream.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "litestream" {
  role_name       = "litestream"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/litestream"

  backend = "spiffe"

  token_policies = [vault_policy.litestream.name]
}

resource "vault_policy" "rustical" {
  name = "rustical"

  policy = <<EOT
path "${vault_kv_secret_v2.oidc_client_rustical.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "rustical" {
  role_name       = "rustical"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/rustical"

  backend = "spiffe"

  token_policies = [vault_policy.rustical.name]
}

resource "vault_policy" "victoriametrics" {
  name = "victoriametrics"

  policy = <<EOT
path "${vault_kv_secret_v2.scaleway_cockpit_par.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "victoriametrics" {
  role_name       = "victoriametrics"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/victoriametrics-scrape"

  backend = "spiffe"

  token_policies = [vault_policy.victoriametrics.name]
}
