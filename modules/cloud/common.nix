{ config, pkgs, lib, modulesPath, ... }:
with pkgs;
let
  inherit (config.system.build) toplevel;
  db = closureInfo { rootPaths = [ toplevel ]; };
  devPath = "/dev/disk/by-partlabel/NIXOS";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpzrZLU0peDu1otGtP2GcCeQIkI8kmfHjnwpbfpWBkv"
  ];

  services.openssh = {
    enable = true;
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
  };

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
      "net.core.rmem_max" = 2500000;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = [ "ip_tables" ];
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

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
    options = [ "subvol=nix" "noatime" "compress-force=zstd" "space_cache=v2" ];
  };

  fileSystems."/persist" = {
    device = devPath;
    fsType = "btrfs";
    options = [ "subvol=persist" "noatime" "compress-force=zstd" "space_cache=v2" ];
    neededForBoot = true;
  };

  system.build.image = vmTools.runInLinuxVM (runCommand "image"
    {
      preVM = ''
        mkdir $out
        diskImage=$out/nixos.img
        ${vmTools.qemu}/bin/qemu-img create -f raw $diskImage $(( $(cat ${db}/total-nar-size) + 500000000 ))
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
    mkdir -p /mnt/{boot,nix,persist}
    mount -o subvol=boot,compress-force=zstd,space_cache=v2 /dev/vda2 /mnt/boot
    mount -o subvol=nix,compress-force=zstd,space_cache=v2 /dev/vda2 /mnt/nix
    mount -o subvol=persist,compress-force=zstd,space_cache=v2 /dev/vda2 /mnt/persist
    export NIX_STATE_DIR=$TMPDIR/state
    nix-store --load-db < ${db}/registration
    nixos-install --root /mnt --system ${toplevel} --no-channel-copy --no-root-passwd --substituters ""
  '');

  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      experimental.http3 = true;
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
            permanent = false;
          };
        };
        https = {
          address = ":443";
          http.tls.certResolver = "le";
          http3 = { };
        };
      };
      certificatesResolvers.le.acme = {
        email = "blackhole@nichi.co";
        storage = config.services.traefik.dataDir + "/acme.json";
        keyType = "EC256";
        tlsChallenge = { };
      };
      ping.manualRouting = true;
    };
    dynamicConfigOptions = {
      tls.options.default = {
        minVersion = "VersionTLS12";
        sniStrict = true;
      };
      http = {
        routers = {
          ping = {
            rule = "Host(`${config.networking.fqdn}`)";
            service = "ping@internal";
          };
        };
      };
    };
  };

  documentation.nixos.enable = false;
}
