{ config, pkgs, lib, ... }:
let
  cfg = config.environment.backup;
in
{

  options.environment.backup = {
    enable = lib.mkEnableOption "backup";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      restic = { sopsFile = ./secrets.yaml; };
      backup = { sopsFile = ./secrets.yaml; };
    };

    programs.ssh = {
      knownHosts = {
        "u326664.your-storagebox.de" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        };
      };
      extraConfig = ''
        Host backup
          User u326664
          HostName u326664.your-storagebox.de
          Port 23
          IdentityFile ${config.sops.secrets.backup.path}
      '';
    };
  };

}
