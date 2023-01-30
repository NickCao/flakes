{ pkgs, config, modulesPath, self, inputs, ... }: {

  sops.secrets = {
    hydra = { group = "hydra"; mode = "0440"; };
    hydra-github = { group = "hydra"; mode = "0440"; };
    carinae = { };
  };

  nix.settings = {
    auto-optimise-store = true;
    allowed-uris = [ "https://github.com" "https://gitlab.com" ];
    trusted-users = [ "root" ];
    max-jobs = 4;
    cores = 16;
  };

  services.postgresql = {
    package = pkgs.postgresql_15;
    settings = {
      max_connections = 100;
      shared_buffers = "4GB";
      effective_cache_size = "12GB";
      maintenance_work_mem = "1GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
      work_mem = "6990kB";
      min_wal_size = "1GB";
      max_wal_size = "4GB";
      max_worker_processes = 6;
      max_parallel_workers_per_gather = 3;
      max_parallel_workers = 6;
      max_parallel_maintenance_workers = 3;
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

  cloud.services.carinae.config = {
    ExecStart = "${inputs.carinae.packages."${pkgs.system}".default}/bin/carinae -l 127.0.0.1:8004";
    EnvironmentFile = config.sops.secrets.carinae.path;
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          hydra = {
            rule = "Host(`hydra.nichi.co`)";
            entryPoints = [ "https" ];
            service = "hydra";
          };
          cache = {
            rule = "Host(`cache.nichi.co`)";
            entryPoints = [ "https" ];
            service = "cache";
          };
        };
        services = {
          hydra.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:3000"; }];
          };
          cache.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8004"; }];
          };
        };
      };
    };
  };

}
