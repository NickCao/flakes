{ config, pkgs, lib, ... }:
{
  sops.secrets.v2ray = {
    sopsFile = ./secrets.yaml;
    restartUnits = [ "v2ray.service" ];
  };
  services.v2ray = {
    enable = true;
    configFile = config.sops.secrets.v2ray.path;
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.v2ray = {
      rule = "Host(`${config.networking.fqdn}`) && Path(`/ping`)";
      service = "v2ray";
    };
    services.v2ray = {
      loadBalancer.servers = [{
        url = "http://127.0.0.1:9001";
      }];
    };
  };
}
