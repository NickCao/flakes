{ config, pkgs, ... }:
{
  programs.ssh = {
    knownHosts = {
      "u273007.your-storagebox.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };
    extraConfig = ''
      Host backup
        User u273007
        HostName u273007.your-storagebox.de
        Port 23
        IdentityFile ${config.sops.secrets.backup.path}
    '';
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/persist" "/nix" ];
  };

  services.restic.backups = {
    var = {
      repository = "sftp:backup:backup";
      passwordFile = config.sops.secrets.restic.path;
      paths = [ "/persist/var" ];
      timerConfig = {
        OnCalendar = "daily";
      };
    };
    git = {
      repository = "sftp:backup:backup";
      passwordFile = config.sops.secrets.restic.path;
      paths = [ "/persist/home/git" ];
      timerConfig = {
        OnCalendar = "weekly";
      };
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    settings = {
      max_connections = 300;
      shared_buffers = "16GB";
      effective_cache_size = "48GB";
      maintenance_work_mem = "2GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "20971kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 12;
      max_parallel_workers_per_gather = 4;
      max_parallel_workers = 12;
      max_parallel_maintenance_workers = 4;
    };
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    compression = "zstd";
    startAt = "weekly";
  };

  nix = {
    package = pkgs.nixVersions.stable;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

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

  users = {
    mutableUsers = false;
    users = {
      root.openssh.authorizedKeys.keys = pkgs.keys;
      nickcao = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = pkgs.keys;
      };
    };
  };

  services.sshcert.enable = true;
  services.openssh.enable = true;
  services.fstrim.enable = true;

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  environment.systemPackages = with pkgs;[
    tmux
    restic
    git
  ];

  environment.persistence."/persist" = {
    directories = [
      "/var"
      "/home"
    ];
  };

  system.stateVersion = "21.05";
}
