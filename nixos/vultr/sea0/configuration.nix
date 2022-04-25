{ config, pkgs, ... }:
let
  dynamic-pool = "10.208.0.0/12";
  nat64-prefix = "2a0c:b641:69c:4ed4:0:4::/96";
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
    secrets.bgp_passwd = {
      sopsFile = ../../../modules/bgp/secrets.yaml;
      owner = "bird2";
      reloadUnits = [ "bird2.service" ];
    };
  };

  services.gravity-ng = {
    enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:4ed0::1/128" ];
    bird = {
      spine.enable = true;
      prefix = "2a0c:b641:69c:4ed0::/60";
      pattern = "grv*";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:4ed4:0:4::/96";
      oif = "enp1s0";
      allow = [ "2a0c:b641:69c::/48" ];
    };
  };
}
