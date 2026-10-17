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
