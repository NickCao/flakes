{
  config,
  lib,
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
        "s3.bucket-lookup=dns"
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
            text = config.lib.openbao.mkAgent {
              role = "restic";
              tokenPath = "/run/restic-backups-persist/token";
              templates = lib.singleton {
                destination = "/run/restic-backups-persist/credentials";
                contents = ''
                  {{ with secret "secrets/scaleway_iam_restic" }}
                  {{ if not (regexMatch "^https://[0-9a-zA-Z]([0-9a-zA-Z-]{0,61}[0-9a-zA-Z])?([.][0-9a-zA-Z]([0-9a-zA-Z-]{0,61}[0-9a-zA-Z])?)+$" .Data.data.api_endpoint) }}
                  {{ sprig_fail "Restic api_endpoint must be https:// followed by a domain name only" }}
                  {{ end }}
                  {{ if not (regexMatch "^[0-9a-zA-Z]+$" .Data.data.access_key) }}
                  {{ sprig_fail "Scaleway access_key must be a non-empty alphanumeric string" }}
                  {{ end }}
                  {{ if not (regexMatch "^[0-9a-zA-Z-]+$" .Data.data.secret_key) }}
                  {{ sprig_fail "Scaleway secret_key must be non-empty and contain only letters, digits, or dashes" }}
                  {{ end }}
                  {{ if not (regexMatch "^[0-9a-zA-Z-]+$" .Data.data.name) }}
                  {{ sprig_fail "Restic bucket name must be non-empty and contain only letters, digits, or dashes" }}
                  {{ end }}
                  RESTIC_REPOSITORY=s3:{{ .Data.data.api_endpoint }}/{{ .Data.data.name }}/${cfg.prefix}
                  AWS_ACCESS_KEY_ID={{ .Data.data.access_key }}
                  AWS_SECRET_ACCESS_KEY={{ .Data.data.secret_key }}
                  {{ end }}
                '';
              };
            };
          })
        ];
      };
    };
  };
}
