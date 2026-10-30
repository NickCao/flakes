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
      api_endpoint = module.nichi_backup_ams.api_endpoint
      name         = module.nichi_backup_ams.name
      access_key   = scaleway_iam_api_key.restic.access_key
      secret_key   = scaleway_iam_api_key.restic.secret_key
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

resource "vault_kv_secret_v2" "vultr_bgp_password" {
  mount                = vault_mount.secrets.path
  name                 = "vultr_bgp_password"
  data_json_wo_version = 1
  data_json_wo = jsonencode(
    {
      password = local.secrets.vultr.bgp_password
    }
  )
}

resource "vault_kv_secret_v2" "gravity" {
  mount                = vault_mount.secrets.path
  name                 = "gravity"
  data_json_wo_version = 1
  data_json_wo = jsonencode(
    {
      registry    = local.secrets.gravity.registry
      private_key = local.secrets.gravity.private_key
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

resource "vault_policy" "bgp" {
  name = "bgp"

  policy = <<EOT
path "${vault_kv_secret_v2.vultr_bgp_password.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "bgp" {
  role_name       = "bgp"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/bgp"

  backend = "spiffe"

  token_policies = [vault_policy.bgp.name]
}

resource "vault_policy" "gravity" {
  name = "gravity"

  policy = <<EOT
path "${vault_kv_secret_v2.gravity.path}" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "gravity" {
  role_name       = "gravity"
  role_type       = "jwt"
  user_claim      = "sub"
  bound_audiences = ["openbao"]
  bound_subject   = "spiffe://nichi.link/gravity"

  backend = "spiffe"

  token_policies = [vault_policy.gravity.name]
}
