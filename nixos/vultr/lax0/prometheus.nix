{ config, pkgs, lib, data, ... }:
let
  cfg = config.services.prometheus;
  targets = lib.mapAttrsToList (mame: node: node.fqdn) data.nodes ++ [
    "hydra.nichi.link"
  ];
in
{
  sops.secrets.alert = { };
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
        static_configs = [{ inherit targets; }];
      }
      {
        job_name = "caddy";
        scheme = "https";
        metrics_path = "/caddy";
        static_configs = [{ inherit targets; }];
      }
    ];
    rules = [
      (builtins.toJSON {
        groups = [{
          name = "metrics";
          rules = [
            {
              alert = "NodeDown";
              expr = "up == 0";
              for = "3m";
              annotations = {
                summary = "node {{ $labels.host }} down for job {{ $labels.job }}";
              };
            }
            {
              alert = "UnitFailed";
              expr = "systemd_units_active_code == 3";
              for = "1m";
              annotations = {
                summary = "unit {{ $labels.name }} on {{ $labels.host }} failed";
              };
            }
            {
              alert = "DNSError";
              expr = "dns_query_result_code != 0";
              for = "5m";
              annotations = {
                summary = "dns query for {{ $labels.domain }} IN {{ $labels.record_type }} on {{ $labels.host }} via {{ $labels.server }} failed with rcode {{ $labels.rcode }}";
              };
            }
            {
              alert = "OOM";
              expr = "mem_available_percent < 20";
              annotations = {
                summary = ''node {{ $labels.host }} low in memory, {{ $value | printf "%.2f" }} percent available'';
              };
            }
            {
              alert = "DiskFull";
              expr = "disk_used_percent { path = '/nix' } > 80";
              annotations = {
                summary = ''node {{ $labels.host }} disk full, {{ $value | printf "%.2f" }} percent used'';
              };
            }
          ];
        }];
      })
    ];
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
