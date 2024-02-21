{ config, pkgs, lib, data, ... }:
let
  cfg = config.services.prometheus;
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes ++ [
    "hydra.nichi.link"
  ];
in
{
  sops.secrets = {
    alert = { };
    prometheus = {
      owner = config.systemd.services.prometheus.serviceConfig.User;
      reloadUnits = [ "prometheus.service" ];
    };
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${config.networking.fqdn}/prom";
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "7d";
    globalConfig = {
      scrape_interval = "1m";
      evaluation_interval = "1m";
    };
    scrapeConfigs = [
      {
        job_name = "metrics";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        static_configs = [{ inherit targets; }];
      }
      {
        job_name = "caddy";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        metrics_path = "/caddy";
        static_configs = [{ inherit targets; }];
      }
    ];
    rules = lib.singleton (builtins.toJSON {
      groups = [{
        name = "metrics";
        rules = [
          {
            alert = "NodeDown";
            expr = ''up == 0'';
          }
          {
            alert = "OOM";
            expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1'';
          }
          {
            alert = "DiskFull";
            expr = ''node_filesystem_avail_bytes{mountpoint=~"/persist|/data"} / node_filesystem_size_bytes < 0.1'';
          }
          {
            alert = "UnitFailed";
            expr = ''node_systemd_unit_state{state="failed"} == 1'';
          }
        ];
      }];
    });
    alertmanagers = [{
      static_configs = [{
        targets = [ "127.0.0.1:8009" ];
      }];
    }];
  };

  cloud.services.prometheus-ntfy-bridge.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --no-check ${../../../fn/alert.ts}";
    MemoryDenyWriteExecute = false;
    EnvironmentFile = [ config.sops.secrets.alert.path ];
    Environment = [ "PORT=8009" "DENO_DIR=/tmp" ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ config.networking.fqdn ];
      path = [ "/prom" "/prom/*" ];
    }];
    handle = [{
      handler = "reverse_proxy";
      upstreams = [{ dial = "${cfg.listenAddress}:${builtins.toString cfg.port}"; }];
    }];
  }];

}
