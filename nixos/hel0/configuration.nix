{ config, pkgs, lib, ... }:
{
  programs.ssh.knownHosts = {
    "8.214.124.155".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1Zi5APlqAX7GRhNDNgYAz+BEOTk4wjbr1pNdciEOcV";
  };

  nix = {
    autoOptimiseStore = true;
    trustedUsers = [ "root" ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
    buildMachines = [{
      hostName = "8.214.124.155";
      systems = [ "x86_64-linux" ];
      sshUser = "root";
      sshKey = config.sops.secrets.plct.path;
      maxJobs = 64;
      supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
    }];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
    hostName = "hel0";
    domain = "nichi.link";
  };

  systemd.network.networks = {
    enp41s0 = {
      name = "enp41s0";
      DHCP = "ipv4";
      address = [ "2a01:4f9:3a:40c9::1/64" ];
      gateway = [ "fe80::1" ];
    };
  };

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpzrZLU0peDu1otGtP2GcCeQIkI8kmfHjnwpbfpWBkv"
  ];

  services.openssh.enable = true;

  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
      "/home"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  system.stateVersion = "21.05";
}
