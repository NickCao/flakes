{ config, pkgs, lib, ... }:
let
  cfg = config.environment.baseline;
in
with lib;
{
  options.environment.baseline = {
    enable = mkEnableOption "baseline configurations";
  };
  config = lib.mkIf cfg.enable {
    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
        dates = "weekly";
      };
    };

    services.resolved.extraConfig = ''
      DNSStubListener=no
    '';

    programs.command-not-found.enable = false;
    documentation.nixos.enable = false;
  };
}
