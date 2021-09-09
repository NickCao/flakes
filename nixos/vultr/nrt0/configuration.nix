{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = { };
      woff = { };
      bark = { };
      traefik = { owner = config.systemd.services.traefik.serviceConfig.User; };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
  networking = {
    hostName = "nrt0";
    domain = "nichi.link";
  };
  services.gravity = {
    enable = true;
    config = config.sops.secrets.rait.path;
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
  services.dns = {
    enable = true;
    nat64 = config.services.divi.prefix;
  };
  services.bgp = {
    enable = true;
    node = "2a0c:b641:69c:7860::/60";
    prefixes = [ "2a0c:b641:690::/48" "2a0c:b641:69c::/48" "2a0c:b641:691::/48" ];
  };
  services.consul = {
    enable = true;
    webUi = true;
    interface.bind = "enp1s0";
    interface.advertise = "enp1s0";
    extraConfig = {
      server = true;
      datacenter = "global";
      bootstrap_expect = 3;
      retry_join = [ "nrt0.nichi.link" "sin0.nichi.link" "sea0.nichi.link" ];
    };
  };
  services.nomad = {
    enable = true;
    enableDocker = false;
    settings = {
      datacenter = "nrt";
      client = {
        enabled = true;
      };
      server = {
        enabled = true;
        bootstrap_expect = 3;
      };
      consul = {
        server_auto_join = true;
      };
    };
  };
}
