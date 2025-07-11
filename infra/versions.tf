terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
    }
    sops = {
      source = "carlpett/sops"
    }
    hydra = {
      source = "DeterminateSystems/hydra"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    keycloak = {
      source = "keycloak/keycloak"
    }
    oci = {
      source = "oracle/oci"
    }
  }
  encryption {
    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.default
    }
    state {
      method   = method.aes_gcm.default
      enforced = true
    }
    plan {
      method   = method.aes_gcm.default
      enforced = true
    }
  }
}
