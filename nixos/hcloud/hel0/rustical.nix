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
    preStart = config.lib.openbao.mkAgent {
      role = "rustical";
      tokenPath = "/run/rustical/token";
      destination = "/run/rustical/credentials";
      contents = ''
        {{ with secret "secrets/oidc_client_rustical" }}
        RUSTICAL_OIDC__CLIENT_ID={{ .Data.data.client_id }}
        RUSTICAL_OIDC__CLIENT_SECRET={{ .Data.data.client_secret }}
        {{ end }}
      '';
    };
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
