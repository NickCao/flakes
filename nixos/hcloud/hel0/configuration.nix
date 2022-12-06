{ config, pkgs, ... }:
{

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/persist" "/nix" ];
  };

  services.restic.backups.persist = {
    repository = "sftp:backup:backup";
    passwordFile = config.sops.secrets.restic.path;
    paths = [ "/persist" ];
    timerConfig = {
      OnCalendar = "daily";
    };
  };

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
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
    lo = {
      name = "lo";
      routes = [{
        routeConfig = {
          Destination = "2a01:4f9:3a:40c9::/64";
          Type = "local";
        };
      }];
    };
  };

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  services.sshcert.enable = true;
  services.openssh.enable = true;

  environment.persistence."/persist" = {
    directories = [
      "/var"
    ];
  };

  environment.baseline.enable = true;
  environment.backup.enable = true;

  system.stateVersion = "21.05";
}
