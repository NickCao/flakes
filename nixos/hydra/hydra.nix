{
  pkgs,
  config,
  lib,
  ...
}:
{

  sops.secrets = {
    hydra-github = {
      group = "hydra";
      mode = "0440";
    };
    harmonia = {
      mode = "0440";
    };
  };

  nix = {
    settings = rec {
      trusted-users = [ "root" ];
      auto-optimise-store = true;
      allowed-uris = [
        "https://github.com"
        "https://gitlab.com"
        "github:"
      ];
      max-jobs = 32;
      cores = 64 / max-jobs;
    };
    channel.enable = lib.mkForce true;
  };

  systemd.services.nix-daemon.serviceConfig.Environment = [ "TMPDIR=/var/tmp" ];

  services.postgresql = {
    package = pkgs.postgresql_17;
    settings = {
      allow_alter_system = false;
      # https://pgtune.leopard.in.ua
      # DB Version: 17
      # OS Type: linux
      # DB Type: mixed
      # Total Memory (RAM): 128 GB
      # CPUs num: 64
      # Connections num: 100
      # Data Storage: hdd
      max_connections = 100;
      shared_buffers = "32GB";
      effective_cache_size = "96GB";
      maintenance_work_mem = "2GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 4;
      effective_io_concurrency = 2;
      work_mem = "41943kB";
      huge_pages = "try";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 64;
      max_parallel_workers_per_gather = 4;
      max_parallel_workers = 64;
      max_parallel_maintenance_workers = 4;
    };
  };

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.nichi.co";
    useSubstitutes = true;
    notificationSender = "hydra@nichi.co";
    extraConfig = ''
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.hydra-github.path}
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
    '';
  };

  services.harmonia = {
    enable = true;
    signKeyPaths = [ config.sops.secrets.harmonia.path ];
    settings = {
      bind = "127.0.0.1:5000";
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "hydra.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:3000"; } ];
        }
      ];
    }
    {
      match = [ { host = [ "cache.nichi.co" ]; } ];
      handle = [
        {
          handler = "encode";
          encodings.zstd = { };
          match.headers = {
            "Content-Type" = [ "application/x-nix-archive" ];
          };
        }
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = config.services.harmonia.settings.bind; } ];
        }
      ];
    }
  ];
}
