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
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };

    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
        dates = "weekly";
      };
    };

    networking.firewall.enable = false;

    services.resolved.extraConfig = ''
      DNSStubListener=no
    '';

    programs.command-not-found.enable = false;
    documentation.nixos.enable = false;
  };
}
