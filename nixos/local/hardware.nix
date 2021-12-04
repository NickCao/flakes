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

  fileSystems."/var/cache" = {
    device = "/dev/disk/by-uuid/91f775b5-f17e-41cd-98d7-fd24cc7a5c41";
    fsType = "btrfs";
    options = [ "subvol=cache" "noatime" "compress-force=zstd" ];
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

  environment.etc.crypttab.text = ''
    test PARTUUID=334ecef1-fc71-4ffa-8f27-338a99db67a6 - tpm2-device=auto,fido2-device=auto
  '';
}
