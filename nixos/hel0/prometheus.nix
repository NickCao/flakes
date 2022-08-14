{ config, ... }:
let cfg = config.services.prometheus; in
{
  sops.secrets.alertmanager = { };
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
        job_name = "rspamd";
        scheme = "http";
        static_configs = [{
          targets = [ "localhost:11334" ];
        }];
      }
      {
        job_name = "metrics";
        scheme = "https";
        static_configs = [{
          targets = [
            "nrt0.nichi.link"
            "sin0.nichi.link"
            "sea0.nichi.link"
            "hel0.nichi.link"
          ];
        }];
      }
      {
        job_name = "traefik";
        scheme = "https";
        metrics_path = "/traefik";
        static_configs = [{
          targets = [
            "nrt0.nichi.link"
            "sin0.nichi.link"
            "sea0.nichi.link"
            "hel0.nichi.link"
          ];
        }];
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
              for = "2m";
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
              alert = "TraefikError";
              expr = "traefik_config_reloads_failure_total > 0";
              annotations = {
                summary = "traefik on node {{ $labels.host }} failed to reload config";
              };
            }
          ];
        }];
      })
    ];
    alertmanagers = [{
      path_prefix = "/alert";
      static_configs = [{
        targets = [ "${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}" ];
      }];
    }];
    alertmanager = {
      enable = true;
      webExternalUrl = "https://${config.networking.fqdn}/alert";
      listenAddress = "127.0.0.1";
      port = 9093;
      environmentFile = [ config.sops.secrets.alertmanager.path ];
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [{
          name = "telegram";
          telegram_configs = [{
            api_url = "https://api.telegram.org";
            bot_token = "$TELEGRAM";
            chat_id = 893182727;
            # message = "";
            parse_mode = "HTML";
          }];
        }];
        route = {
          receiver = "telegram";
        };
      };
    };
  };
  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          prometheus = {
            rule = "Host(`${config.networking.fqdn}`) && PathPrefix(`/prom`)";
            entryPoints = [ "https" ];
            service = "prometheus";
          };
          alertmanager = {
            rule = "Host(`${config.networking.fqdn}`) && PathPrefix(`/alert`)";
            entryPoints = [ "https" ];
            service = "alertmanager";
            middlewares = [ "alertmanager" ];
          };
        };
        middlewares = {
          alertmanager.basicAuth = {
            users = [ "admin:$apr1$uOuAXH9e$7wtqGxJArzJFknM0BXfT91" ];
            removeheader = true;
          };
        };
        services = {
          prometheus.loadBalancer.servers = [{
            url = "http://${cfg.listenAddress}:${builtins.toString cfg.port}";
          }];
          alertmanager.loadBalancer.servers = [{
            url = "http://${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}";
          }];
        };
      };
    };
  };
}
