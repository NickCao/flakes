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
        Host backup
          HostName fm1622.rsync.net
          User fm1622
          IdentityFile ${config.sops.secrets.restic-keys.path}
      '';
    };

    sops.secrets = {
      restic-repo = { sopsFile = ./secrets.yaml; };
      restic-pass = { sopsFile = ./secrets.yaml; };
      restic-envs = { sopsFile = ./secrets.yaml; };
      restic-keys = { sopsFile = ./secrets.yaml; };
    };

    environment.systemPackages = [ pkgs.restic ];
  };

}
