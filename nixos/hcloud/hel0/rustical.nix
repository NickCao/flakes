{
  lib,
  config,
  ...
}:
let
  cfg = config.services.rustical.settings;
in
{
  sops.secrets.rustical = {
    restartUnits = [ "rustical.service" ];
  };

  services.rustical = {
    enable = true;
    environmentFiles = [ config.sops.secrets.rustical.path ];
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
