{ config, pkgs, lib, ... }:
let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };

    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
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
        upstreams = with config.services.prometheus.exporters.node;[{
          dial = "${listenAddress}:${toString port}";
        }];
      }];
    }];
  };
}
