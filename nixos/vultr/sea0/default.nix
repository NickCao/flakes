{ config, ... }:
{
  imports = [ ../common.nix ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };
  networking.hostName = "sea0";
  services.dns.secondary.enable = true;
  services.gravity = {
    enable = true;
    reload.enable = true;
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
