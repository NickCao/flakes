{ config, lib, pkgs, modulesPath, self, inputs, ... }:
let
  device = "/dev/disk/by-partlabel/NIXOS";
  opts = [ "noatime" "compress-force=zstd" "space_cache=v2" ];
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    ./knot.nix
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nixpkgs.overlays = [ self.overlays.default ];

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
    };
  };

  boot = {
    loader.grub.device = "/dev/sda";
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sr_mod" ];
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "defaults" "mode=755" ];
    };
    "/boot" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=boot" ] ++ opts;
    };
    "/nix" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=nix" ] ++ opts;
    };
    "/persist" = {
      inherit device;
      fsType = "btrfs";
      options = [ "subvol=persist" ] ++ opts;
      neededForBoot = true;
    };
  };

  environment.persistence."/persist" = {
    files = [
      "/var/lib/sops.key"
    ];
    directories = [
      "/var/lib/knot"
    ];
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall.enable = false;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [{ address = ((import ../../zones/common.nix).nodes.iad0.ipv6); prefixLength = 64; }];
      ipv6.routes = [{ prefixLength = 0; via = "fe80::1"; }];
    };
  };

  services.resolved = {
    llmnr = "false";
    extraConfig = ''
      DNSStubListener=no
    '';
  };

  services.openssh.enable = true;
  services.getty.autologinUser = "root";
  services.sshcert.enable = true;

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = pkgs.keys;
  };

  documentation.nixos.enable = false;

  system.stateVersion = "22.05";
}
