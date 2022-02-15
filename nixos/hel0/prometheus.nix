{ config, lib, pkgs, ... }:
let cfg = config.services.prometheus; in
{
  sops.secrets.telegram = { };
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
    scrapeConfigs = [{
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
    }];
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
                summary = "node {{ $labels.host }} down";
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
              for = "2m";
              annotations = {
                summary = "dns query for {{ $labels.domain }} IN {{ $labels.record_type }} on {{ $labels.host }} via {{ $labels.server }} failed with rcode {{ $labels.rcode }}";
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
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [{
          name = "telegram";
          webhook_configs = [{
            url = "http://127.0.0.1:9087/alert/893182727";
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
            service = "prometheus";
          };
          alertmanager = {
            rule = "Host(`${config.networking.fqdn}`) && PathPrefix(`/alert`)";
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

  cloud.services.prometheus-bot = {
    exec = "${pkgs.prometheus_bot}/bin/prometheus_bot -c ${(pkgs.formats.yaml {}).generate "config.yaml" {
      send_only = true;
      time_zone = "Asia/Shanghai";
      time_outdata = "01/02 15:04:05";
      template_path = ./alert.tmpl;
    }} -token-from \${CREDENTIALS_DIRECTORY}/token -l 127.0.0.1:9087";
    creds = [ "token:${config.sops.secrets.telegram.path}" ];
  };
}
