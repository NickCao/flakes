{ config, ... }:
{
  sops.secrets = {
    litestream = { };
  };

  systemd.services.litestream.serviceConfig = {
    AmbientCapabilities = [ "CAP_DAC_OVERRIDE" ]; # FIXME
    StateDirectory = [ "litestream" ];
  };

  services.litestream = {
    enable = true;
    environmentFile = config.sops.secrets.litestream.path;
    settings = rec {
      sync-interval = "30m";
      max-sync-ltx-files = 0;
      region = "fr-par";
      endpoint = "s3.${region}.scw.cloud";
      bucket = "nichi-litestream-par";

      dbs = [
        {
          path = "/var/lib/rustical/db.sqlite3";
          replica = {
            type = "s3";
            path = "rustical";
          };
        }
      ];
    };
  };
}
