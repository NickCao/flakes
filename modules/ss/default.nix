{ config, pkgs, lib, ... }:
{
  sops.secrets.v2ray = {
    sopsFile = ./secrets.yaml;
    restartUnits = [ "v2ray.service" ];
  };
  cloud.services.v2ray = {
    exec = "${pkgs.v2ray}/bin/v2ray run -c \${CREDENTIALS_DIRECTORY}/secret.json";
    creds = [ "secret.json:${config.sops.secrets.v2ray.path}" ];
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
