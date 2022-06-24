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
}
