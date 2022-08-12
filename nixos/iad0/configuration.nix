{ config, lib, pkgs, modulesPath, self, ... }:
let
  device = "/dev/disk/by-partlabel/NIXOS";
  opts = [ "noatime" "compress-force=zstd" "space_cache=v2" ];
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  nixpkgs.overlays = [ self.overlays.default ];

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
    };
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = false;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [{ address = "2a01:4ff:f0:db00::1"; prefixLength = 64; }];
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
