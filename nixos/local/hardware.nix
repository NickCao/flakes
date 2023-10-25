{ lib, ... }:
let
  mkMount = subvol: {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "compress-force=zstd" ];
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
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
  };

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/CRYPTROOT";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [
      "same-cpu-crypt"
      "submit-from-crypt-cpus"
      "fido2-device=auto"
    ];
  };
}
