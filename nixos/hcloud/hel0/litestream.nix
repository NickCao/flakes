{ lib, pkgs, ... }:
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
    };
    environment = {
      AWS_SHARED_CREDENTIALS_FILE = "/run/litestream/credentials";
    };
    path = [ pkgs.getent ]; # for bao agent
    preStart = ''
      ${lib.getExe' pkgs.spire "spire-agent"} api fetch jwt \
        -audience openbao \
        -socketPath /run/spire/agent/public/api.sock \
        -output json | ${lib.getExe pkgs.jq} -r '.[0].svids.[0].svid' \
        > /run/litestream/token
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "litestream-openbao-agent.hcl" ''
          vault {
            address = "http://127.0.0.1:8200"
          }
          auto_auth {
            method "jwt" {
              mount_path = "auth/spiffe"
              config {
                path = "/run/litestream/token"
                role = "litestream"
              }
            }
          }
          template {
            contents = <<EOT
          {{ with secret "secrets/scaleway_iam_litestream" }}
          [default]
          aws_access_key_id={{ .Data.data.access_key }}
          aws_secret_access_key={{ .Data.data.secret_key }}
          {{ end }}
          EOT
            destination = "/run/litestream/credentials"
          }
        ''}
    '';
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
