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
    useDHCP = true;
    useNetworkd = true;
    firewall.enable = false;
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
