{ config, pkgs, lib, ... }:
with lib;
{
  sops.secrets.telegraf = {
    sopsFile = ./secrets.yaml;
  };
  services.telegraf = {
    enable = true;
    environmentFiles = [ config.sops.secrets.telegraf.path ];
    extraConfig = {
      outputs = {
        influxdb_v2 = {
          urls = [ "https://stats.nichi.co" ];
          token = "$INFLUX_TOKEN";
          organization = "nichi";
          bucket = "stats";
        };
      };
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
      };
    };
  };
}
