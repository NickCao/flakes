{
  lib,
  config,
  pkgs,
  utils,
  ...
}:
let
  cfg = {
    dav_push = {
      enabled = true;
    };
    frontend = {
      enabled = true;
      allow_password_login = false;
    };
    http = {
      host = "127.0.0.1";
      payload_limit_mb = 4;
      port = 4000;
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
      claim_userid = "preferred_username";
      scopes = [
        "openid"
        "profile"
      ];
      allow_sign_up = true;
    };
  };
in
{

  sops.secrets.rustical = {
    restartUnits = [ "rustical.service" ];
  };

  cloud.services.rustical.config = {
    EnvironmentFile = [ config.sops.secrets.rustical.path ];
    Environment = [ "RUSTICAL_DATA_STORE__SQLITE__DB_URL=%S/rustical/db.sqlite3" ];
    StateDirectory = [ "rustical" ];
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.rustical)
      "--config-file"
      ((pkgs.formats.toml { }).generate "config.toml" cfg)
    ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = [ "cal.nichi.co" ]; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "${cfg.http.host}:${toString cfg.http.port}";
      };
    };
  };

}
