{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{
  sops.secrets.oauth2-proxy-homeassistant = {
    restartUnits = [ config.systemd.services.oauth2-proxy-homeassistant.name ];
  };

  cloud.services.oauth2-proxy-homeassistant.unit = {
    Wants = [ "network-online.target" ];
    After = [ "network-online.target" ];
  };

  cloud.services.oauth2-proxy-homeassistant.config = {
    EnvironmentFile = [ config.sops.secrets.oauth2-proxy-homeassistant.path ];
    RuntimeDirectory = "oauth2-proxy-homeassistant";
    UMask = "0000";
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.oauth2-proxy)
      "--provider=keycloak-oidc"
      "--client-id=homeassistant"
      "--redirect-url=https://ha.nichi.co/oauth2/callback"
      "--oidc-issuer-url=https://id.nichi.co/realms/nichi"
      "--email-domain=*"
      "--allowed-role=trusted"
      "--code-challenge-method=S256"
      "--http-address=unix://run/oauth2-proxy-homeassistant/proxy.sock"
      "--reverse-proxy"
      "--upstream=http://homeassistant.lan:8123"
    ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = [ "ha.nichi.co" ]; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "unix//run/oauth2-proxy-homeassistant/proxy.sock";
      };
    };
  };
}
