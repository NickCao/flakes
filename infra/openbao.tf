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
