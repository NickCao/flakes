{ config, pkgs, lib, ... }:
with pkgs;
let
  toplevel = config.system.build.toplevel;
  db = closureInfo { rootPaths = [ toplevel ]; };
  devPath = "/dev/disk/by-partlabel/NIXOS";
in
{
  boot = {
    postBootCommands = ''
      echo "Fix" | ${parted}/bin/parted /dev/vda ---pretend-input-tty print
      ${parted}/bin/parted --script /dev/vda resizepart 2 100%
      ${btrfs-progs}/bin/btrfs fi resize max /nix
    '';
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
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
      nativeBuildInputs = [ parted btrfs-progs mount util-linux nixUnstable config.system.build.nixos-install ];
    } ''
    parted --script /dev/vda mklabel gpt mkpart BOOT 1MiB 2MiB set 1 bios_grub on mkpart NIXOS btrfs 2MiB 100%
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
