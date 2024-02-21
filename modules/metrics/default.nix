{ config, pkgs, lib, ... }:
let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {

    sops.secrets.metrics = {
      sopsFile = ./secrets.yaml;
      restartUnits = [ "caddy.service" ];
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = [ config.sops.secrets.metrics.path ];

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };

    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = (pkgs.formats.yaml { }).generate "config.yml" {
        modules = {
          http_2xx = {
            prober = "http";
            http.preferred_ip_protocol = "ip6";
          };
        };
      };
    };

    cloud.caddy.settings.apps.http.servers.default.routes = [
      {
        match = [{
          host = [ config.networking.fqdn ];
          path = [ "/metrics" ];
        }];
        handle = [
          {
            handler = "authentication";
            providers.http_basic.accounts = [{
              username = "prometheus";
              password = "{env.PROM_PASSWD}";
            }];
          }
          {
            handler = "reverse_proxy";
            upstreams = with config.services.prometheus.exporters.node;[{
              dial = "${listenAddress}:${toString port}";
            }];
          }
        ];
      }
      {
        match = [{
          host = [ config.networking.fqdn ];
          path = [ "/probe" ];
        }];
        handle = [
          {
            handler = "authentication";
            providers.http_basic.accounts = [{
              username = "prometheus";
              password = "{env.PROM_PASSWD}";
            }];
          }
          {
            handler = "reverse_proxy";
            upstreams = with config.services.prometheus.exporters.blackbox;[{
              dial = "${listenAddress}:${toString port}";
            }];
          }
        ];
      }
    ];

  };
}
