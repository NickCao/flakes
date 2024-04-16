{ config, ... }: {

  imports = [ ../common.nix ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };

  networking.hostName = "nrt0";

  services.gravity.config = config.sops.secrets.ranet.path;

}
