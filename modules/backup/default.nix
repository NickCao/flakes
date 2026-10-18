{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.environment.backup;
in
{

  options.environment.backup = {
    enable = lib.mkEnableOption "backup";
    prefix = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "hosts/${config.networking.hostName}";
    };
    passwordFile = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.restic-password.path;
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.persist = {
      passwordFile = cfg.passwordFile;
      environmentFile = "-/run/restic-backups-persist/credentials";
      initialize = true;
      createWrapper = false;
      paths = [ "/persist" ];
      exclude = [
        "/persist/var/lib/sops.key"
        "/persist/var/lib/spire"
        "/persist/var/lib/systemd/coredump"
      ];
      extraOptions = [
        "s3.storage-class=ONEZONE_IA"
        "s3.connections=16"
      ];
      extraBackupArgs = [
        "--one-file-system"
        "--exclude-caches"
        "--no-scan"
        "--retry-lock 2h"
      ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "4h";
        FixedRandomDelay = true;
        Persistent = true;
      };
    };

    systemd.services.restic-backups-persist = {
      serviceConfig = {
        Environment = [ "GOGC=20" ];
        RuntimeDirectoryMode = "0700";
        ExecStartPre = lib.mkBefore [
          (utils.systemdUtils.lib.makeJobScript {
            name = "restic-prepare-secret";
            enableStrictShellChecks = true;
            text = ''
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
                  template_config {
                    exit_on_retry_failure = true
                  }
                  template {
                    error_on_missing_key = true
                    perms = "0600"
                    contents = <<EOT
                  {{ with secret "secrets/scaleway_iam_restic" }}
                  RESTIC_REPOSITORY=s3:{{ .Data.data.api_endpoint }}/{{ .Data.data.name }}/${cfg.prefix}
                  AWS_ACCESS_KEY_ID={{ .Data.data.access_key }}
                  AWS_SECRET_ACCESS_KEY={{ .Data.data.secret_key }}
                  {{ end }}
                  EOT
                    destination = "/run/restic-backups-persist/credentials"
                  }
                ''}
            '';
          })
        ];
      };
    };
  };
}
