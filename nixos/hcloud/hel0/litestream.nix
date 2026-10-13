{ config, ... }:
{
  sops.secrets = {
    litestream = { };
  };

  systemd.services.litestream.serviceConfig = {
    DynamicUser = true;
    StateDirectory = [
      "litestream"
      "rustical"
    ];
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
