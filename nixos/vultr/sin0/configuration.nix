{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };
  networking.hostName = "sin0";
  services.dns.secondary.enable = true;
  services.gravity = {
    enable = true;
    reload.enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:f250::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:f250::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:f254:0:4::/96";
    };
  };
}
