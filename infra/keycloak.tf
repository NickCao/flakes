resource "keycloak_realm" "nichi" {
  realm                       = "nichi"
  default_signature_algorithm = "RS256"
}
