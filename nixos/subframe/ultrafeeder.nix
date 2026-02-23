{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{
  sops.secrets.oauth2-proxy-ultrafeeder = {
    restartUnits = [ config.systemd.services.oauth2-proxy-ultrafeeder.name ];
  };

  cloud.services.oauth2-proxy-ultrafeeder.unit = {
    Wants = [ "network-online.target" ];
    After = [ "network-online.target" ];
  };

  cloud.services.oauth2-proxy-ultrafeeder.config = {
    EnvironmentFile = [ config.sops.secrets.oauth2-proxy-ultrafeeder.path ];
    RuntimeDirectory = "oauth2-proxy-ultrafeeder";
    UMask = "0000";
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.oauth2-proxy)
      "--provider=keycloak-oidc"
      "--client-id=ultrafeeder"
      "--redirect-url=https://ultrafeeder.nichi.co/oauth2/callback"
      "--oidc-issuer-url=https://id.nichi.co/realms/nichi"
      "--email-domain=*"
      "--allowed-role=trusted"
      "--code-challenge-method=S256"
      "--http-address=unix://run/oauth2-proxy-ultrafeeder/proxy.sock"
      "--reverse-proxy"
      "--upstream=http://ultrafeeder.lan:8080"
    ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = [ "ultrafeeder.nichi.co" ]; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "unix//run/oauth2-proxy-ultrafeeder/proxy.sock";
      };
    };
  };
}
