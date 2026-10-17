resource "vault_mount" "pki_users" {
  path = "pki-users"
  type = "pki"

  default_lease_ttl_seconds = 30 * 24 * 60 * 60       # 30 days
  max_lease_ttl_seconds     = 10 * 365 * 24 * 60 * 60 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "users" {
  backend = vault_mount.pki_users.path
  type    = "internal"

  common_name = "Nichi Yorozuya User CA"
  key_type    = "ec"
  key_bits    = 256
  ttl         = "87600h"
}

resource "vault_mount" "pki_users_intermediate" {
  path = "pki-users-intermediate"
  type = "pki"

  default_lease_ttl_seconds = 30 * 24 * 60 * 60      # 30 days
  max_lease_ttl_seconds     = 1 * 365 * 24 * 60 * 60 # 1 year
}

resource "vault_pki_secret_backend_intermediate_cert_request" "pki_users_intermediate" {
  backend = vault_mount.pki_users_intermediate.path
  type    = "internal"

  common_name = "Nichi Yorozuya User Intermediate CA E1"
  key_type    = "ec"
  key_bits    = 256
}

resource "vault_pki_secret_backend_root_sign_intermediate" "pki_users_intermediate" {
  backend     = vault_mount.pki_users.path
  issuer_ref  = vault_pki_secret_backend_root_cert.users.issuer_id
  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_users_intermediate.csr
  common_name = vault_pki_secret_backend_intermediate_cert_request.pki_users_intermediate.common_name
  ttl         = "8760h"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "pki_users_intermediate" {
  backend     = vault_mount.pki_users_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki_users_intermediate.certificate_bundle
}

