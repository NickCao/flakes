{ config, ... }:
let
  cfg = config.services.vaultwarden.config;
in
{

  sops.secrets.vault = {
    restartUnits = [ "vaultwarden.service" ];
  };

  services.vaultwarden = {
    enable = true;
    config = {
      SIGNUPS_ALLOWED = false;
      SENDS_ALLOWED = false;
      EMERGENCY_ACCESS_ALLOWED = false;
      ORG_CREATION_USERS = "none";
      DOMAIN = "https://vault.nichi.co";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8003;
      IP_HEADER = "X-Forwarded-For";
    };
    backupDir = "/var/lib/bitwarden_rs.bak";
    environmentFile = config.sops.secrets.vault.path;
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "vault.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "${cfg.ROCKET_ADDRESS}:${toString cfg.ROCKET_PORT}"; } ];
        }
      ];
    }
  ];
}
