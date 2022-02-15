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
          rules = [{
            alert = "NodeDown";
            expr = "up == 0";
            for = "5m";
            annotations = {
              summary = "node {{ $labels.instance }} down";
              description = "{{ $labels.instance }} has been down for more than 5 minutes";
            };
          }];
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
      extraFlags = [ "--cluster.advertise-address=${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}" ];
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
    }} -token-from \${CREDENTIALS_DIRECTORY}/token -l 127.0.0.1:9087";
    creds = [ "token:${config.sops.secrets.telegram.path}" ];
  };
}
