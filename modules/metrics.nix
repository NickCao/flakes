{ config, lib, ... }:
with lib;
let
  cfg = config.services.metrics;
  telegrafConfig = config.services.telegraf.extraConfig.outputs.prometheus_client;
in
{
  options.services.metrics = {
    enable = mkEnableOption "export server metrics";
  };
  config = mkIf cfg.enable {
    services.vector = {
      enable = true;
      settings = {
        sources = {
          host = {
            type = "host_metrics";
            collectors = [
              "filesystem"
              "load"
              "memory"
            ];
            filesystem.mountpoints.includes = [
              "/nix"
              "/data"
            ];
          };
          telegraf = {
            type = "prometheus_scrape";
            endpoints = [ "http://${telegrafConfig.listen}${telegrafConfig.path}" ];
          };
        };
        sinks = {
          prom = {
            inputs = [ "host" "telegraf" ];
            type = "prometheus_exporter";
            address = "127.0.0.1:9273";
          };
        };
      };
    };
    services.telegraf = {
      enable = true;
      extraConfig = {
        inputs = {
          systemd_units = { };
          dns_query = {
            servers = [
              "1.1.1.1"
              "1.0.0.1"
            ];
            domains = [ "nichi.co" ];
            record_type = "A";
            timeout = 5;
          };
        };
        outputs = {
          prometheus_client = {
            listen = "127.0.0.1:9274";
            metric_version = 2;
            path = "/metrics";
          };
        };
      };
    };

    cloud.caddy.settings.apps.http.servers.default.routes = [{
      match = [{
        host = [ config.networking.fqdn ];
        path = [ "/metrics" ];
      }];
      handle = [{
        handler = "reverse_proxy";
        upstreams = [{ dial = config.services.vector.settings.sinks.prom.address; }];
      }];
    }];
  };
}
