{ config, pkgs, lib, modulesPath, ... }:
with pkgs;
let
  inherit (config.system.build) toplevel;
  db = closureInfo { rootPaths = [ toplevel ]; };
  devPath = "/dev/disk/by-partlabel/NIXOS";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (import ../.).default
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  services.getty.autologinUser = "root";
  services.gateway.enable = true;
  services.metrics.enable = true;
  services.sshcert.enable = true;
  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  boot = {
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.rmem_max" = 2500000;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  services.resolved = {
    llmnr = "false";
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
    domain = "nichi.link";
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" "mode=755" ];
  };

  fileSystems."/boot" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=boot" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  fileSystems."/nix" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=nix" "noatime" "compress-force=zstd" "space_cache=v2" "x-systemd.growfs" ];
  };

  fileSystems."/persist" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=persist" "noatime" "compress-force=zstd" "space_cache=v2" ];
    neededForBoot = true;
  };

  system.build.install = pkgs.writeShellApplication {
    name = "install";
    text = ''
      sfdisk /dev/vda <<EOT
      label: gpt
      type="BIOS boot",        name="BOOT",  size=2M
      type="Linux filesystem", name="NIXOS", size=+
      EOT

      sleep 2

      NIXOS=/dev/disk/by-partlabel/NIXOS
      mkfs.btrfs --force $NIXOS
      mkdir -p /fsroot
      mount $NIXOS /fsroot

      btrfs subvol create /fsroot/boot
      btrfs subvol create /fsroot/nix
      btrfs subvol create /fsroot/persist

      OPTS=compress-force=zstd,space_cache=v2
      mkdir -p /mnt/{boot,nix,persist}
      mount -o subvol=boot,$OPTS    $NIXOS /mnt/boot
      mount -o subvol=nix,$OPTS     $NIXOS /mnt/nix
      mount -o subvol=persist,$OPTS $NIXOS /mnt/persist

      mkdir -p /mnt/persist/var/lib/
      curl -s http://169.254.169.254/latest/user-data -o /mnt/persist/var/lib/sops.key

      nixos-install --root /mnt --system ${config.system.build.toplevel} \
        --no-channel-copy --no-root-passwd \
        --option extra-substituters "https://cache.nichi.co" \
        --option trusted-public-keys "hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk="

      reboot
    '';
    checkPhase = ''
      mkdir -p $out/nix-support
      echo "file install $out/bin/install" >> $out/nix-support/hydra-build-products
    '';
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
    ];
  };

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
