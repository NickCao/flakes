{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = { };
      woff = { };
      traefik = { };
    };
  };
  networking = {
    hostName = "nrt0";
  };
  services.gravity = {
    enable = true;
    envfile = config.sops.secrets.rait.path;
    config = pkgs.writeText "rait.conf" ''
      registry     = env("REGISTRY")
      operator_key = env("OPERATOR_KEY")
      private_key  = env("PRIVATE_KEY")
      namespace    = "gravity"
      remarks = {
        prefix     = "2a0c:b641:69c:7860::/60"
        maintainer = "nickcao"
        name       = "nick_nrt"
      }
      transport {
        address_family = "ip4"
        address        = "${config.networking.fqdn}"
        send_port      = 50120
        mtu            = 1400
        ifprefix       = "grv4x"
        ifgroup        = 54
        fwmark         = 54
      }
      transport {
        address_family = "ip6"
        address        = "${config.networking.fqdn}"
        send_port      = 50121
        mtu            = 1400
        ifprefix       = "grv6x"
        ifgroup        = 56
        fwmark         = 54
      }
      babeld {
        enabled = true
      }
    '';
    address = "2a0c:b641:69c:7860::1/126";
    group = 54;
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:7860::2/126 dev gravity"
    ];
  };
  services.divi = {
    enable = true;
    prefix = "2a0c:b641:69c:7864:0:4::/96";
    address = "2a0c:b641:69c:7864:0:5:0:3/128";
  };
  services.dns.secondary.enable = true;
  services.bgp = {
    enable = true;
    node = "2a0c:b641:69c:7860::/60";
    prefixes = [ "2a0c:b641:690::/48" "2a0c:b641:69c::/48" "2a0c:b641:691::/48" ];
  };
}
