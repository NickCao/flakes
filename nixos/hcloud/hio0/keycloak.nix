{ config, pkgs, ... }:
{
  services.keycloak = {
    enable = true;
    settings = {
      http-enabled = true;
      http-host = "127.0.0.1";
      http-port = config.lib.ports.keycloak;
      proxy-headers = "xforwarded";
      hostname = "id.nichi.co";
      cache = "local";
    };
    database.passwordFile = toString (pkgs.writeText "password" "keycloak");
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ config.services.keycloak.settings.hostname ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.services.keycloak.settings.http-port}"; } ];
        }
      ];
    }
  ];
}
