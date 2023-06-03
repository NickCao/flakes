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
      restic-repo = { sopsFile = ./secrets.yaml; };
      restic-pass = { sopsFile = ./secrets.yaml; };
      restic-envs = { sopsFile = ./secrets.yaml; };
    };

    environment.systemPackages = [ pkgs.restic ];
  };

}
