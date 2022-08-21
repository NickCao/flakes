{ pkgs, ... }:
let
  sata = "/dev/disk/by-id/wwn-0x500003981ba001ae-part2";
  nvme = "/dev/disk/by-id/nvme-eui.002538b321b3dde9-part2";
  opts = [
    "noatime"
    "compress-force=zstd"
    "space_cache=v2"
  ];
in
{
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/nvme-eui.002538b321b3dde9";
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  fileSystems."/boot" = {
    fsType = "btrfs";
    device = sata;
    options = [ "subvol=boot" ] ++ opts;
  };

  fileSystems."/nix" = {
    fsType = "btrfs";
    device = sata;
    options = [ "subvol=nix" ] ++ opts;
  };

  fileSystems."/data" = {
    fsType = "btrfs";
    device = sata;
    options = [ "subvol=data" ] ++ opts;
  };

  fileSystems."/persist" = {
    fsType = "btrfs";
    device = nvme;
    options = [ "subvol=persist" ] ++ opts;
    neededForBoot = true;
  };
}
