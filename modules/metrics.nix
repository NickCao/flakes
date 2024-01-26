{ config, pkgs, lib, ... }:
let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {
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
          systemd = {
            type = "prometheus_scrape";
            endpoints = with config.services.prometheus.exporters.systemd;[
              "http://${listenAddress}:${toString port}/metrics"
            ];
          };
          blackbox = {
            type = "prometheus_scrape";
            endpoints = with config.services.prometheus.exporters.blackbox;[
              "http://${listenAddress}:${toString port}/probe"
            ];
            query = {
              module = [ "dns" ];
              target = [ "1.0.0.1" ];
            };
          };
        };
        transforms = {
          aggregated = {
            type = "remap";
            inputs = [ "host" "systemd" "blackbox" ];
            source = ".tags.host = \"${config.networking.hostName}\"";
          };
        };
        sinks = {
          prom = {
            inputs = [ "aggregated" ];
            type = "prometheus_exporter";
            address = "127.0.0.1:9273";
          };
        };
      };
    };

    services.prometheus.exporters.systemd = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9275;
    };

    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9276;
      configFile = (pkgs.formats.json { }).generate "config.json" {
        modules = {
          dns = {
            prober = "dns";
            dns = {
              query_name = "nichi.co";
              query_type = "NS";
              valid_rcodes = [ "NOERROR" ];
            };
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
