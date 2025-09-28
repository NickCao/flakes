resource "keycloak_realm" "nichi" {
  realm                       = "nichi"
  default_signature_algorithm = "RS256"
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

resource "keycloak_openid_client" "miniflux" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "miniflux"
  name        = "Miniflux"
  access_type = "CONFIDENTIAL"

  base_url            = "https://rss.nichi.co"
  valid_redirect_uris = ["https://rss.nichi.co/oauth2/oidc/callback"]
  web_origins         = ["https://rss.nichi.co/oauth2/oidc/redirect"]
}

# https://lennart-k.github.io/rustical/setup/oidc/
resource "keycloak_openid_client" "rustical" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "rustical"
  name        = "Rustical"
  access_type = "CONFIDENTIAL"

  implicit_flow_enabled = true
  standard_flow_enabled = true
  valid_redirect_uris   = ["https://cal.nichi.co/frontend/login/oidc/callback"]
}

# https://element-hq.github.io/matrix-authentication-service/setup/sso.html#keycloak
resource "keycloak_openid_client" "matrix-authentication-service" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "matrix-authentication-service"
  name        = "Matrix Authentication Service"
  access_type = "CONFIDENTIAL"

  standard_flow_enabled               = true
  valid_redirect_uris                 = ["https://matrix-auth.nichi.co/upstream/callback/01K34XRT1QHE1541KQ7HRRY15M"]
  frontchannel_logout_enabled         = false
  backchannel_logout_session_required = true
  backchannel_logout_url              = "https://matrix-auth.nichi.co/upstream/backchannel-logout/01K34XRT1QHE1541KQ7HRRY15M"
}

resource "keycloak_realm_events" "events" {
  realm_id                     = keycloak_realm.nichi.id
  admin_events_enabled         = true
  admin_events_details_enabled = true
  events_enabled               = true
  events_listeners             = ["jboss-logging"]
}
