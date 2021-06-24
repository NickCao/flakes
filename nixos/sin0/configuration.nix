{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ../modules/secrets.yaml;
    secrets = {
      rait = {
        sopsFile = ./secrets.yaml;
      };
      bird = {
        owner = "bird2";
      };
      private_zsk = {
        mode = "0444";
        path = "/etc/coredns/zsk.private";
      };
      public_zsk = {
        mode = "0444";
        path = "/etc/coredns/zsk.key";
      };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
  networking = {
    hostName = "sin0";
    domain = "nichi.link";
  };
  services.gravity = {
    enable = true;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:f250::1/126";
    group = 54;
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:f250::2/126 dev gravity"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 54 suppress_ifgroup 54 pref 1024"
    ];
  };
  services.divi = {
    enable = true;
    prefix = "2a0c:b641:69c:f254:0:4::/96";
    address = "2a0c:b641:69c:f254:0:5:0:3/128";
  };
  services.dns = {
    enable = true;
    nat64 = config.services.divi.prefix;
  };
  services.bgp = {
    enable = true;
    node = "2a0c:b641:69c:f250::/60";
    prefixes = [ "2a0c:b641:690::/48" "2a0c:b641:69c::/48" "2a0c:b641:692::/48" ];
    include = config.sops.secrets.bird.path;
  };
}
