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
      signupsAllowed = false;
      sendsAllowed = false;
      emergencyAccessAllowed = false;
      orgCreationUsers = "none";
      domain = "https://vault.nichi.co";
      rocketAddress = "127.0.0.1";
      rocketPort = 8003;
    };
    backupDir = "/var/lib/bitwarden_rs/backup";
    environmentFile = config.sops.secrets.vault.path;
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "vault.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "${cfg.rocketAddress}:${toString cfg.rocketPort}"; } ];
        }
      ];
    }
  ];
}
