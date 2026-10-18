{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.rustical.settings;
in
{
  systemd.services.rustical = {
    serviceConfig = {
      RestartSec = 10;
      EnvironmentFile = [ "-%t/rustical/credentials" ];
    };
    path = [ pkgs.getent ]; # for bao agent
    preStart = ''
      ${lib.getExe' pkgs.spire "spire-agent"} api fetch jwt \
        -audience openbao \
        -socketPath /run/spire/agent/public/api.sock \
        -output json | ${lib.getExe pkgs.jq} -r '.[0].svids.[0].svid' \
        > /run/rustical/token
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "rustical-openbao-agent.hcl" ''
          vault {
            address = "http://127.0.0.1:8200"
          }
          auto_auth {
            method "jwt" {
              mount_path = "auth/spiffe"
              config {
                path = "/run/rustical/token"
                role = "rustical"
              }
            }
          }
          template_config {
            exit_on_retry_failure = true
          }
          template {
            error_on_missing_key = true
            perms = "0600"
            contents = <<EOT
          {{ with secret "secrets/oidc_client_rustical" }}
          RUSTICAL_OIDC__CLIENT_ID={{ .Data.data.client_id }}
          RUSTICAL_OIDC__CLIENT_SECRET={{ .Data.data.client_secret }}
          {{ end }}
          EOT
            destination = "/run/rustical/credentials"
          }
        ''}
    '';
  };

  services.rustical = {
    enable = true;
    settings = {
      dav_push = {
        enabled = true;
      };
      frontend = {
        enabled = true;
        allow_password_login = false;
      };
      http = {
        bind = "127.0.0.1:4000";
        payload_limit_mb = 4;
        session_cookie_samesite_strict = false;
      };
      nextcloud_login = {
        enabled = true;
      };
      tracing = {
        opentelemetry = false;
      };
      oidc = {
        name = "Keycloak";
        issuer = "https://id.nichi.co/realms/nichi";
        client_id = "rustical";
        claim_userid = "sub";
        scopes = [
          "openid"
          "profile"
        ];
        allow_sign_up = true;
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = [ "cal.nichi.co" ]; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = cfg.http.bind;
      };
    };
  };
}
