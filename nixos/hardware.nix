{ config, lib, pkgs, modulesPath, ... }:

{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    fsType = "tmpfs";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=var" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B815-6B63";
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=home" "noatime" "compress-force=zstd" ];
  };

  fileSystems."/home/nickcao/Data" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=data" "noatime" "compress-force=zstd" ];
  };
  /*
    fileSystems."/home/nickcao/Test" = {
      device = "/dev/mapper/test";
      fsType = "ext4";
      encrypted = {
        enable = true;
        blkDev = "/dev/disk/by-partuuid/334ecef1-fc71-4ffa-8f27-338a99db67a6";
        label = "test";
      };
    };
  */
}
