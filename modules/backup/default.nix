{ config, lib, ... }:
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
      restic-envs = {
        sopsFile = ./secrets.yaml;
      };
    };

    services.restic.backups.persist = {
      repositoryFile = config.sops.secrets.restic-repo.path;
      passwordFile = config.sops.secrets.restic-pass.path;
      environmentFile = config.sops.secrets.restic-envs.path;
      paths = [ "/persist" ];
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
    };

    systemd.services.restic-backups-persist = {
      serviceConfig.Environment = [ "GOGC=20" ];
    };
  };
}
