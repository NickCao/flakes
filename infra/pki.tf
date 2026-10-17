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

resource "vault_jwt_auth_backend" "oidc" {
  path = "oidc"
  type = "oidc"

  oidc_discovery_url = "https://id.nichi.co/realms/nichi"
  oidc_client_id     = keycloak_openid_client.openbao.client_id
  oidc_client_secret = keycloak_openid_client.openbao.client_secret
}

resource "vault_pki_secret_backend_role" "oidc_user" {
  backend    = vault_mount.pki_users_intermediate.path
  name       = "user"
  issuer_ref = "default"

  ttl     = 30 * 24 * 60 * 60
  max_ttl = 30 * 24 * 60 * 60

  allowed_domains_template = true
  allowed_domains = [
    "{{identity.entity.aliases.${vault_jwt_auth_backend.oidc.accessor}.metadata.email}}"
  ]

  allow_bare_domains          = true
  allow_subdomains            = false
  allow_localhost             = false
  allow_ip_sans               = false
  allow_wildcard_certificates = false

  require_cn          = false
  use_csr_common_name = false
  use_csr_sans        = true

  key_type       = "any"
  key_usage      = ["DigitalSignature"]
  client_flag    = true
  server_flag    = false
  generate_lease = false

  depends_on = [
    vault_pki_secret_backend_intermediate_set_signed.pki_users_intermediate
  ]
}

resource "vault_policy" "oidc_user_certificates" {
  name = "oidc-user-certificates"

  policy = <<-EOT
    path "${vault_mount.pki_users_intermediate.path}/sign/${vault_pki_secret_backend_role.oidc_user.name}" {
      capabilities = ["update"]
      required_parameters = ["csr"]
      allowed_parameters = {
        csr       = []
        ttl       = []
        format    = []
      }
    }
  EOT
}

resource "vault_jwt_auth_backend_role" "oidc_user" {
  backend   = vault_jwt_auth_backend.oidc.path
  role_name = "user-certificates"
  role_type = "oidc"

  user_claim            = "sub"
  oidc_scopes           = ["email"]
  allowed_redirect_uris = keycloak_openid_client.openbao.valid_redirect_uris

  claim_mappings = {
    email = "email"
  }

  token_policies = [vault_policy.oidc_user_certificates.name]
  token_ttl      = 15 * 60
  token_max_ttl  = 15 * 60
}

