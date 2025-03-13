{ config, ... }:
{

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };

  services.gravity.config = config.sops.secrets.ranet.path;

}
