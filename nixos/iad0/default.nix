{ config, lib, pkgs, modulesPath, self, inputs, ... }:
let
  device = "/dev/disk/by-partlabel/NIXOS";
  opts = [ "noatime" "compress-force=zstd" "space_cache=v2" ];
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.impermanence.nixosModules.impermanence
  ];

  nixpkgs.overlays = [ self.overlays.default ];

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
  };

  boot = {
    loader.grub.device = "/dev/sda";
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sr_mod" ];
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "defaults" "mode=755" ];
    };
    "/boot" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=boot" ] ++ opts;
    };
    "/nix" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=nix" ] ++ opts;
    };
    "/persist" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=persist" ] ++ opts;
      neededForBoot = true;
    };
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = false;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [{ address = ((import ../../zones/common.nix).nodes.iad0.ipv6); prefixLength = 64; }];
      ipv6.routes = [{ prefixLength = 0; via = "fe80::1"; }];
    };
  };

  services.openssh.enable = true;
  services.getty.autologinUser = "root";

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = pkgs.keys;
  };

  documentation.nixos.enable = false;

  system.stateVersion = "22.05";
}
