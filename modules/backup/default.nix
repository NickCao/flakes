{ config, pkgs, lib, ... }:
let
  cfg = config.environment.backup;
in
{

  options.environment.backup = {
    enable = lib.mkEnableOption "backup";
  };

  config = lib.mkIf cfg.enable {

    programs.ssh = {
      extraConfig = ''
        Host rsyncnet
          HostName     fm1622.rsync.net
          User         fm1622
          IdentityFile ${config.sops.secrets.restic-keys.path}
      '';
      knownHosts."fm1622.rsync.net".publicKey = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z
      '';
    };

    sops.secrets = {
      restic-pass = { sopsFile = ./secrets.yaml; };
      restic-keys = { sopsFile = ./secrets.yaml; };
    };

    services.restic.backups.persist = {
      package = pkgs.restic-hpn;
      repository = "sftp://dummy.invalid/backup";
      passwordFile = config.sops.secrets.restic-pass.path;
      paths = [ "/persist" ];
      extraBackupArgs = [
        "-o sftp.command='${pkgs.openssh_hpn}/bin/ssh rsyncnet -s sftp'"
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

    environment.systemPackages = [ pkgs.restic ];
  };

}
