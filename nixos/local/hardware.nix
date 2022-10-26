{ lib, ... }:
let
  mkMount = subvol: {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "noatime" "compress-force=zstd" ];
  };
in
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = mkMount "nix";

  fileSystems."/persist" = mkMount "persist" // { neededForBoot = true; };

  fileSystems."/efi" = {
    device = "/dev/disk/by-path/pci-0000:06:00.0-nvme-1-part1";
    fsType = "vfat";
  };

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-path/pci-0000:06:00.0-nvme-1-part2";
    crypttabExtraOpts = [ "fido2-device=auto" ];
  };
}
