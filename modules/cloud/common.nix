{ config, pkgs, modulesPath, ... }:
with pkgs;
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (import ../.).default
    (import ../.).cloud.filesystems
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  services.gateway.enable = true;
  services.metrics.enable = true;
  services.sshcert.enable = true;
  services.openssh.enable = true;

  boot = {
    tmpOnTmpfs = true;
    loader.grub.device = "/dev/vda";
    kernel.sysctl = {
      "net.core.rmem_max" = 2500000;
    };
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "nichi.link";
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
