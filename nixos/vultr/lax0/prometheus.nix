{ config, pkgs, lib, data, ... }:
let
  cfg = config.services.prometheus;
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes ++ [
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
              expr = ''systemd_unit_state{state="failed"} == 1'';
              for = "1m";
              annotations = {
                summary = "unit {{ $labels.name }} on {{ $labels.host }} failed";
              };
            }
            {
              alert = "DNSError";
              expr = "probe_dns_query_succeeded != 1";
              for = "5m";
              annotations = {
                summary = "dns query on {{ $labels.host }} failed";
              };
            }
            {
              alert = "OOM";
              expr = "(host_memory_available_bytes / host_memory_total_bytes) * 100 < 20";
              annotations = {
                summary = ''node {{ $labels.host }} low in memory, {{ $value | printf "%.2f" }} percent available'';
              };
            }
            {
              alert = "DiskFull";
              expr = "host_filesystem_used_ratio * 100 > 90";
              annotations = {
                summary = ''node {{ $labels.host }} disk full, {{ $value | printf "%.2f" }} percent used'';
              };
            }
            {
              alert = "ZoneStale";
              expr = ''knot_zone_serial{host="iad0"} - on(zone) group_right knot_zone_serial{host!="iad0"} > 0'';
              annotations = {
                summary = ''node {{ $labels.host }} zone {{ $labels.zone }} stale'';
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
