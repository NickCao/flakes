{ config, pkgs, ... }:
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

  services.traefik.dynamicConfigOptions.http = {
    routers.vault = {
      rule = "Host(`vault.nichi.co`)";
      entryPoints = [ "https" ];
      service = "vault";
    };
    services.vault.loadBalancer = {
      passHostHeader = true;
      servers = [{ url = "http://${cfg.rocketAddress}:${toString cfg.rocketPort}"; }];
    };
  };

}
