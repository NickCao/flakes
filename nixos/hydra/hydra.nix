{ pkgs, config, lib, ... }: {

  sops.secrets = {
    hydra = { group = "hydra"; mode = "0440"; };
    hydra-github = { group = "hydra"; mode = "0440"; };
    harmonia = { mode = "0440"; };
  };

  nix = {
    settings = rec {
      trusted-users = [ "root" ];
      auto-optimise-store = true;
      allowed-uris = [ "https://github.com" "https://gitlab.com" ];
      max-jobs = 8;
      cores = 64 / max-jobs;
    };
  };

  systemd.services.nix-daemon.serviceConfig.Environment = [
    "TMPDIR=/var/tmp"
  ];

  services.postgresql = {
    package = pkgs.postgresql_15;
    settings = {
      max_connections = 100;
      shared_buffers = "16GB";
      effective_cache_size = "48GB";
      maintenance_work_mem = "2GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 4;
      effective_io_concurrency = 2;
      work_mem = "41943kB";
      min_wal_size = "2GB";
      max_wal_size = "8GB";
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
      include ${config.sops.secrets.hydra.path}
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.hydra-github.path}
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>
      <githubstatus>
        jobs = misc:flakes:.*
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>
    '';
  };

  services.harmonia = {
    enable = true;
    signKeyPath = config.sops.secrets.harmonia.path;
    settings = {
      bind = "127.0.0.1:5000";
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [{
        host = [ "hydra.nichi.co" ];
      }];
      handle = [{
        handler = "reverse_proxy";
        upstreams = [{ dial = "127.0.0.1:3000"; }];
      }];
    }
    {
      match = [{
        host = [ "cache.nichi.co" ];
      }];
      handle = [{
        handler = "reverse_proxy";
        upstreams = [{ dial = config.services.harmonia.settings.bind; }];
      }];
    }
  ];

}
