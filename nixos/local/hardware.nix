{ lib, ... }:
let
  mkMount = subvol: {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "noatime" "compress-force=zstd" ];
  };
in
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = mkMount "nix";

  fileSystems."/persist" = mkMount "persist" // { neededForBoot = true; };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/B815-6B63";
    fsType = "vfat";
  };
}
