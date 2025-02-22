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

resource "keycloak_openid_client" "synapse" {
  realm_id    = keycloak_realm.nichi.id
  client_id   = "synapse"
  name        = "Synapse"
  access_type = "CONFIDENTIAL"

  valid_redirect_uris    = ["https://matrix.nichi.co/_synapse/client/oidc/callback"]
  web_origins            = ["https://matrix.nichi.co"]
  backchannel_logout_url = "https://matrix.nichi.co/_synapse/client/oidc/backchannel_logout"
}

resource "keycloak_realm_events" "events" {
  realm_id                     = keycloak_realm.nichi.id
  admin_events_enabled         = true
  admin_events_details_enabled = true
  events_enabled               = true
  events_listeners             = ["jboss-logging"]
}
