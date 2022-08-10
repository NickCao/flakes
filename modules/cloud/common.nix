{ config, pkgs, lib, modulesPath, ... }:
with pkgs;
let
  inherit (config.system.build) toplevel;
  db = closureInfo { rootPaths = [ toplevel ]; };
  devPath = "/dev/disk/by-partlabel/NIXOS";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (import ../.).default
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  programs.command-not-found.enable = false;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  services.gateway.enable = true;
  services.metrics.enable = true;
  services.sshcert.enable = true;
  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
  };

  boot = {
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.rmem_max" = 2500000;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  services.resolved = {
    llmnr = "false";
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
    domain = "nichi.link";
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  fileSystems."/boot" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=boot" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  fileSystems."/nix" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" "space_cache=v2" "x-systemd.growfs" ];
  };

  fileSystems."/persist" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=persist" "noatime" "compress-force=zstd" "space_cache=v2" ];
    neededForBoot = true;
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
    ];
  };

  system.stateVersion = "22.05";
  documentation.nixos.enable = false;
}
