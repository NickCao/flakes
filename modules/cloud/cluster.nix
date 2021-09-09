{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.cluster;
in
{
  options.services.cluster = {
    enable = mkEnableOption "enable clustering";
    datacenter = mkOption {
      type = types.str;
      description = "nomad datacenter";
    };
    servers = mkOption {
      type = types.listOf types.str;
      description = "server addresses";
    };
  };
  config = mkIf cfg.enable {
    services.consul = {
      enable = true;
      webUi = true;
      interface.bind = "enp1s0";
      interface.advertise = "enp1s0";
      extraConfig = {
        server = true;
        datacenter = "global";
        bootstrap_expect = builtins.length cfg.servers;
        retry_join = cfg.servers;
      };
    };
    services.nomad = {
      enable = true;
      enableDocker = false;
      settings = {
        datacenter = cfg.datacenter;
        client = {
          enabled = true;
        };
        server = {
          enabled = true;
          bootstrap_expect = builtins.length cfg.servers;
        };
        consul = {
          server_auto_join = true;
        };
      };
    };
  };
}
