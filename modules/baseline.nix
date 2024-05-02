{
  config,
  pkgs,
  lib,
  ...
}:
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
      kernelParams = [ "ia32_emulation=0" ];
      kernel.sysctl = {
        "kernel.panic" = 60;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        # https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
        "net.core.rmem_max" = 2500000;
      };
    };

    nix = {
      channel.enable = false;
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
        dates = "weekly";
      };
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "auto-allocate-uids"
          "cgroups"
        ];
        auto-allocate-uids = true;
        use-cgroups = true;
      };
    };

    networking.firewall.enable = false;

    services.getty.autologinUser = "root";
    services.fstrim.enable = true;
    services.resolved = {
      llmnr = "false";
      extraConfig = ''
        DNSStubListener=no
        MulticastDNS=off
      '';
    };

    services.zram-generator = {
      enable = true;
      settings.zram0 = {
        compression-algorithm = "zstd";
        zram-size = "ram";
      };
    };

    users.mutableUsers = false;

    environment.stub-ld.enable = false;

    programs.command-not-found.enable = false;
    documentation.nixos.enable = lib.mkForce false;
  };
}
