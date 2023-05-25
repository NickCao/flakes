{ config, ... }:
{
  imports = [ ../common.nix ./services.nix ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      ranet.reloadUnits = [ "gravity.service" ];
      caddy = { };
    };
  };
  networking.hostName = "nrt0";
  services.gravity = {
    enable = true;
    reload.enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:7860::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:7860::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:7864:0:4::/96";
    };
    ipsec = {
      enable = true;
      organization = "nickcao";
      commonName = "nrt0";
      port = 13000;
      interfaces = [ "ens3" ];
      endpoints = [
        { serialNumber = "0"; addressFamily = "ip4"; }
        { serialNumber = "1"; addressFamily = "ip6"; }
      ];
    };
  };
}
