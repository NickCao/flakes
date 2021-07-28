{ config, pkgs, lib, modulesPath, ... }:
with pkgs;
let
  toplevel = config.system.build.toplevel;
  db = closureInfo { rootPaths = [ toplevel ]; };
  devPath = "/dev/disk/by-partlabel/NIXOS";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  users.mutableUsers = false;
  boot = {
    postBootCommands = ''
      ${gptfdisk}/bin/sgdisk -e -d 2 -n 2:0:0 -c 2:NIXOS -p /dev/vda
      ${util-linux}/bin/partx -u /dev/vda
      ${btrfs-progs}/bin/btrfs fi resize max /nix
    '';
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };

  services.getty.autologinUser = "root";

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/boot" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=boot" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  fileSystems."/nix" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  fileSystems."/persist" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=persist" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  system.build.image = vmTools.runInLinuxVM (runCommand "image"
    {
      preVM = ''
        mkdir $out
        diskImage=$out/nixos.img
        ${vmTools.qemu}/bin/qemu-img create -f raw $diskImage 2G
      '';
      nativeBuildInputs = [ gptfdisk btrfs-progs mount util-linux nixUnstable config.system.build.nixos-install ];
    } ''
    sgdisk -Z -n 1:0:+1M -n 2:0:0 -t 1:ef02 -c 1:BOOT -c 2:NIXOS /dev/vda
    mknod /dev/btrfs-control c 10 234
    mkfs.btrfs /dev/vda2
    mkdir /fsroot && mount /dev/vda2 /fsroot
    btrfs subvol create /fsroot/boot
    btrfs subvol create /fsroot/nix
    btrfs subvol create /fsroot/persist
    mkdir -p /mnt/{boot,nix}
    mount -o subvol=boot,compress-force=zstd,space_cache=v2 /dev/vda2 /mnt/boot
    mount -o subvol=nix,compress-force=zstd,space_cache=v2 /dev/vda2 /mnt/nix
    export NIX_STATE_DIR=$TMPDIR/state
    nix-store --load-db < ${db}/registration
    nixos-install --root /mnt --system ${toplevel} --no-channel-copy --no-root-passwd --substituters ""
  '');
}
