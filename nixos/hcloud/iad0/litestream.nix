{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.litestream = {
    serviceConfig = {
      RestartSec = 10;
      DynamicUser = true;
      RuntimeDirectory = [ "litestream" ];
      RuntimeDirectoryMode = "0700";
      StateDirectory = [
        "stalwart"
      ];
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = "/run/litestream/credentials";
    };
    path = [ pkgs.getent ]; # for bao agent
    preStart = config.lib.openbao.mkAgent {
      role = "litestream";
      runtimeDir = "/run/litestream";
      templates = lib.singleton {
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
  };

  cloud.ghostunnel.servers.spiffe-litestream-metrics = {
    listen = "[::]:9377";
    target = config.services.litestream.settings.addr;
    allowURIs = [ "spiffe://nichi.link/victoriametrics" ];
  };

  services.litestream = {
    enable = true;
    settings = rec {
      addr = "127.0.0.1:9376"; # metrics

      sync-interval = "1m";
      max-sync-ltx-files = 0;
      region = "fr-par";
      endpoint = "s3.${region}.scw.cloud";
      bucket = "nichi-litestream-par";

      dbs = [
        {
          path = "/var/lib/stalwart/data.sqlite";
          replica = {
            type = "s3";
            path = "stalwart";
          };
        }
      ];
    };
  };
}
