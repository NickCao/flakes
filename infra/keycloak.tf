resource "keycloak_realm" "nichi" {
  realm                       = "nichi"
  default_signature_algorithm = "RS256"
}

resource "keycloak_role" "trusted" {
  realm_id    = keycloak_realm.nichi.id
  name        = "trusted"
  description = "Trusted"
}

resource "keycloak_openid_client" "mastodon" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "mastodon"
  name        = "Mastodon"
  access_type = "CONFIDENTIAL"

  base_url            = "https://mastodon.nichi.co"
  valid_redirect_uris = ["https://mastodon.nichi.co/auth/auth/openid_connect/callback"]
  web_origins         = ["https://mastodon.nichi.co"]
}

# https://element-hq.github.io/matrix-authentication-service/setup/sso.html#keycloak
resource "keycloak_openid_client" "matrix-authentication-service" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "matrix-authentication-service"
  name        = "Matrix Authentication Service"
  access_type = "CONFIDENTIAL"

  implicit_flow_enabled               = false
  standard_flow_enabled               = true
  valid_redirect_uris                 = ["https://matrix-auth.nichi.co/upstream/callback/01K34XRT1QHE1541KQ7HRRY15M"]
  frontchannel_logout_enabled         = false
  backchannel_logout_session_required = true
  backchannel_logout_url              = "https://matrix-auth.nichi.co/upstream/backchannel-logout/01K34XRT1QHE1541KQ7HRRY15M"
}

resource "keycloak_openid_client_scope" "stalwart" {
  realm_id            = keycloak_realm.nichi.id
  name                = "stalwart"
  description         = "Stalwart mail and collaboration server"
  consent_screen_text = "Stalwart mail and collaboration server"
}

resource "keycloak_openid_audience_protocol_mapper" "stalwart" {
  realm_id                 = keycloak_realm.nichi.id
  name                     = "stalwart"
  client_scope_id          = keycloak_openid_client_scope.stalwart.id
  included_custom_audience = "https://mail.scp.link"
}

resource "keycloak_realm_events" "events" {
  realm_id                     = keycloak_realm.nichi.id
  admin_events_enabled         = true
  admin_events_details_enabled = true
  events_enabled               = true
  events_listeners             = ["jboss-logging"]
}

resource "keycloak_openid_client" "openbao" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "openbao"
  name        = "OpenBao"
  access_type = "CONFIDENTIAL"

  implicit_flow_enabled = false
  standard_flow_enabled = true
  valid_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback",
  ]
  web_origins                         = ["http://127.0.0.1"]
  frontchannel_logout_enabled         = false
  backchannel_logout_session_required = true
  service_accounts_enabled            = false
  direct_access_grants_enabled        = false
  pkce_code_challenge_method          = "S256"
}

resource "keycloak_realm_client_policy_profile" "cimd" {
  name     = "cimd"
  realm_id = keycloak_realm.nichi.id

  executor {
    name = "client-id-metadata-document"
    configuration = {
      cimd-allow-http-scheme = false
      cimd-allow-permitted-domains = jsonencode([
        "stalw.art", # client_uri in CIMD
        "mail.nichi.co",
        "mail.scp.link",
        "localhost", # thunderbird
      ])
      cimd-restrict-same-domain = false
      cimd-required-properties  = jsonencode([])
      cimd-resource-indicator-allow-list = jsonencode([
        "https://mail.nichi.co",
        "https://mail.scp.link"
      ])
      only-allow-confidential-client                           = false
      accept-public-client-with-confidential-client-only-grant = false
    }
  }
}

resource "keycloak_realm_client_policy_profile_policy" "cimd" {
  name     = "cimd"
  realm_id = keycloak_realm.nichi.id

  condition {
    name = "client-id-uri"
    configuration = {
      is-negative-logic                     = false,
      client-id-uri-scheme                  = jsonencode(["https"])
      client-id-uri-allow-permitted-domains = jsonencode(["mail.nichi.co", "mail.scp.link"])
    }
  }

  profiles = [
    keycloak_realm_client_policy_profile.cimd.name
  ]
}

# https://github.com/keycloak/keycloak/pull/53929
resource "keycloak_realm_client_policy_profile" "pkce" {
  name     = "pkce"
  realm_id = keycloak_realm.nichi.id

  executor {
    name = "pkce-enforcer"
    configuration = {
      auto-configure = true
    }
  }
}

resource "keycloak_realm_client_policy_profile_policy" "pkce" {
  name     = "pkce"
  realm_id = keycloak_realm.nichi.id

  condition {
    name = "client-updater-context"
    configuration = {
      is-negative-logic    = false
      update-client-source = jsonencode(["ByAnonymous"])
    }
  }

  profiles = [
    keycloak_realm_client_policy_profile.pkce.name
  ]
}

// https://datatracker.ietf.org/doc/html/draft-ietf-mailmaint-oauth-public-06
resource "keycloak_openid_client_scope" "mail" {
  realm_id            = keycloak_realm.nichi.id
  name                = "urn:ietf:params:oauth:scope:mail"
  description         = "Requests access for a client to manage the user's email"
  consent_screen_text = "Email"
}

resource "keycloak_openid_client_scope" "contacts" {
  realm_id            = keycloak_realm.nichi.id
  name                = "urn:ietf:params:oauth:scope:contacts"
  description         = "Requests access for a client to manage the user's contacts"
  consent_screen_text = "Contacts"
}

resource "keycloak_openid_client_scope" "calendars" {
  realm_id            = keycloak_realm.nichi.id
  name                = "urn:ietf:params:oauth:scope:calendars"
  description         = "Requests access for a client to manage the user's calendars"
  consent_screen_text = "Calendars"
}

resource "keycloak_openid_client_scope" "files" {
  realm_id            = keycloak_realm.nichi.id
  name                = "urn:ietf:params:oauth:scope:files"
  description         = "Requests access for a client to manage the user's files"
  consent_screen_text = "Files"
}

resource "keycloak_realm_optional_client_scopes" "oauth_public" {
  realm_id = keycloak_realm.nichi.id
  optional_scopes = [
    "offline_access",
    keycloak_openid_client_scope.stalwart.name,
    keycloak_openid_client_scope.mail.name,
    keycloak_openid_client_scope.contacts.name,
    keycloak_openid_client_scope.calendars.name,
    keycloak_openid_client_scope.files.name
  ]
}
