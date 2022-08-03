{ config, lib, pkgs, modulesPath, ... }:

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

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/persistent" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=persistent" "noatime" "compress-force=zstd" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B815-6B63";
    fsType = "vfat";
  };

/*
  fileSystems."/test" = {
    device = "/dev/stratis/test/test";
    fsType = "xfs";
    options = [
      "defaults"
      "x-systemd.requires=stratis-fstab-setup@ae3747b0-aa80-4a97-9374-49775ca63a86.service"
      "x-systemd.after=stratis-fstab-setup@ae3747b0-aa80-4a97-9374-49775ca63a86.service"
      "nofail"
    ];
  };
*/
}
