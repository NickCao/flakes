{ config, pkgs, ... }:
let
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };

  services.gravity-ng = {
    enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:4ed0::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:4ed0::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:4ed4:0:4::/96";
    };
  };
}
