{ config, pkgs, lib, ... }:
{
  programs.ssh.knownHosts = {
    "8.214.124.155".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK1Zi5APlqAX7GRhNDNgYAz+BEOTk4wjbr1pNdciEOcV";
    "u273007.your-storagebox.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  };
  programs.ssh.extraConfig = ''
    Host u273007.your-storagebox.de
      User u273007
      Port 23
      IdentityFile ${config.sops.secrets.backup.path}
  '';
  services.restic.backups = {
    backup = {
      repository = "sftp:u273007.your-storagebox.de:backup";
      passwordFile = config.sops.secrets.restic.path;
      paths = [
        "/persist/var/lib/bitwarden_rs"
        "/persist/var/lib/hydra"
        "/persist/var/lib/knot"
        "/persist/var/lib/maddy"
        "/persist/var/lib/postgresql"
        "/persist/var/lib/dendrite"
        "/persist/var/lib/mautrix-telegram"
        "/persist/var/lib/matrix-appservice-irc"
      ];
      timerConfig = {
        OnCalendar = "daily";
      };
    };
  };
  services.postgresql.package = pkgs.postgresql_14;

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
    };
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

  services.sshcert.enable = true;
  services.openssh.enable = true;

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  environment.systemPackages = with pkgs;[
    restic
  ];
  environment.persistence."/persist" = {
    directories = [
      "/var/lib"
      "/home"
    ];
  };

  system.stateVersion = "21.05";
}
