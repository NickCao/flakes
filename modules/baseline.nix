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
        "kernel.panic" = 60;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        # https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
        "net.core.rmem_max" = 2500000;
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

    services.getty.autologinUser = "root";
    services.fstrim.enable = true;
    services.nscd.enableNsncd = true;
    services.resolved = {
      llmnr = "false";
      extraConfig = ''
        DNSStubListener=no
      '';
    };

    users.mutableUsers = false;

    programs.command-not-found.enable = false;
    documentation.nixos.enable = false;
  };
}
