{ config, pkgs, ... }:
{
  systemd.services.litestream = {
    serviceConfig = {
      RestartSec = 10;
      DynamicUser = true;
      StateDirectory = [
        "litestream"
        "rustical"
      ];
      RuntimeDirectory = [
        "litestream"
      ];
      RuntimeDirectoryMode = "0700";
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = "/run/litestream/credentials";
    };
    path = [ pkgs.getent ]; # for bao agent
    preStart = config.lib.openbao.mkAgent {
      role = "litestream";
      tokenPath = "/run/litestream/token";
      destination = "/run/litestream/credentials";
      contents = ''
        {{ with secret "secrets/scaleway_iam_litestream" }}
        {{ if not (regexMatch "^[0-9a-zA-Z]+$" .Data.data.access_key) }}
        {{ sprig_fail "Scaleway access_key must be a non-empty alphanumeric string" }}
        {{ end }}
        {{ if not (regexMatch "^[0-9a-zA-Z-]+$" .Data.data.secret_key) }}
        {{ sprig_fail "Scaleway secret_key must be non-empty and contain only letters, digits, or dashes" }}
        {{ end }}
        [default]
        aws_access_key_id={{ .Data.data.access_key }}
        aws_secret_access_key={{ .Data.data.secret_key }}
        {{ end }}
      '';
    };
  };

  services.litestream = {
    enable = true;
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
