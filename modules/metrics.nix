{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.metrics;
  telegrafConfig = config.services.telegraf.extraConfig;
in
{
  options.services.metrics = {
    enable = mkEnableOption "export server metrics";
  };
  config = mkIf cfg.enable {
    services.telegraf = {
      enable = true;
      extraConfig = {
        inputs = {
          cpu = { };
          disk = {
            ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "overlay" "aufs" "squashfs" ];
          };
          diskio = { };
          mem = { };
          net = { };
          processes = { };
          system = { };
          systemd_units = { };
          dns_query = {
            servers = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            domains = [ "nichi.co" ];
            record_type = "A";
          };
        };
        outputs = {
          prometheus_client = {
            listen = "127.0.0.0:9273";
            metric_version = 2;
            path = "/metrics";
          };
        };
      };
    };
    services.traefik = {
      dynamicConfigOptions = {
        http = {
          routers.telegraf = {
            rule = "Host(`${config.networking.fqdn}`) && Path(`${telegrafConfig.outputs.prometheus_client.path}`)";
            entryPoints = [ "https" ];
            service = "telegraf";
          };
          services.telegraf.loadBalancer.servers = [{
            url = "http://${telegrafConfig.outputs.prometheus_client.listen}";
          }];
        };
      };
    };
  };
}
