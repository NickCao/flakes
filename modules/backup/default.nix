{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.environment.backup;
in
{

  options.environment.backup = {
    enable = lib.mkEnableOption "backup";
  };

  config = lib.mkIf cfg.enable {

    sops.secrets = {
      restic-repo = {
        sopsFile = ./secrets.yaml;
      };
      restic-pass = {
        sopsFile = ./secrets.yaml;
      };
    };

    services.restic.backups.persist = {
      repositoryFile = config.sops.secrets.restic-repo.path;
      passwordFile = config.sops.secrets.restic-pass.path;
      paths = [ "/persist" ];
      exclude = [ "/persist/var/lib/systemd/coredump" ];
      extraOptions = [ "s3.storage-class=ONEZONE_IA" ];
      extraBackupArgs = [
        "--one-file-system"
        "--exclude-caches"
        "--no-scan"
        "--retry-lock 2h"
      ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "4h";
        FixedRandomDelay = true;
        Persistent = true;
      };
      backupPrepareCommand = ''
        ${lib.getExe' pkgs.spire "spire-agent"} api fetch jwt \
          -audience openbao \
          -socketPath /run/spire/agent/public/api.sock \
          -output json | ${lib.getExe pkgs.jq} -r '.[0].svids.[0].svid' \
          > /run/restic-backups-persist/token
        ${lib.getExe pkgs.openbao} agent -exit-after-auth \
          -config ${pkgs.writeText "restic-openbao-agent.hcl" ''
            vault {
              address = "http://127.0.0.1:8200"
            }
            auto_auth {
              method "jwt" {
                mount_path = "auth/spiffe"
                config {
                  path = "/run/restic-backups-persist/token"
                  role = "restic"
                }
              }
            }
            template {
              perms = "0600"
              contents = <<EOT
            {{ with secret "secrets/scaleway_iam_restic" }}
            [default]
            aws_access_key_id={{ .Data.data.access_key }}
            aws_secret_access_key={{ .Data.data.secret_key }}
            {{ end }}
            EOT
              destination = "/run/restic-backups-persist/credentials"
            }
          ''}
      '';
    };

    systemd.services.restic-backups-persist = {
      environment.AWS_SHARED_CREDENTIALS_FILE = "/run/restic-backups-persist/credentials";
      serviceConfig = {
        Environment = [ "GOGC=20" ];
        RuntimeDirectoryMode = "0700";
      };
    };
  };
}
