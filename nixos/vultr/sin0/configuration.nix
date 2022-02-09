{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = { };
    };
  };
  networking.hostName = "sin0";
  services.gravity = {
    enable = true;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:f250::1/126";
    group = 54;
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:f250::2/126 dev gravity"
    ];
  };
  services.divi = {
    enable = true;
    prefix = "2a0c:b641:69c:f254:0:4::/96";
    address = "2a0c:b641:69c:f254:0:5:0:3/128";
  };
  services.dns.secondary.enable = true;
  services.bgp = {
    enable = true;
    node = "2a0c:b641:69c:f250::/60";
    prefixes = [ "2a0c:b641:690::/48" "2a0c:b641:69c::/48" "2a0c:b641:692::/48" ];
  };
}
