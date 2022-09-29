{ config, pkgs, ... }:
{
  programs.ssh = {
    knownHosts = {
      "k11-plct.nichi.link".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7Gb+JDMj+P2Wumrvwbr7lCqyl93gy06b8Af9si7Rye";
      "u273007.your-storagebox.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };
    extraConfig = ''
      Host u273007.your-storagebox.de
        User u273007
        Port 23
        IdentityFile ${config.sops.secrets.backup.path}
      Host k11-plct.nichi.link
        User root
        IdentityFile ${config.sops.secrets.plct.path}
    '';
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/persist" "/nix" ];
  };

  services.restic.backups = {
    files = {
      repository = "sftp:u273007.your-storagebox.de:backup";
      passwordFile = config.sops.secrets.restic.path;
      paths = builtins.map (x: "/persist/var/lib/" + x) [
        "bitwarden_rs"
        "knot"
        "matrix-synapse"
        "mjolnir"
        "private/mautrix-telegram"
        "backup/postgresql"
      ] ++ [ "/persist/home/git" "/persist/var/spool" ];
      timerConfig = {
        OnCalendar = "daily";
      };
    };
  };

  services.postgresql = {
    package = pkgs.postgresql_14;
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
      allowed-uris = [ "https://github.com" "https://gitlab.com" ];
    };
    buildMachines = [
      {
        hostName = "k11-plct.nichi.link";
        systems = [ "x86_64-linux" ];
        maxJobs = 32;
        supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
      }
    ];
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
