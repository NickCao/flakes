{ config, ... }: {

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "lax0";

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:a2a0::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:a2a0::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:a2a4:0:4::/96";
    };
    srv6 = {
      enable = true;
      prefix = "2a0c:b641:69c:a2a";
    };
    ipsec = {
      enable = true;
      organization = "nickcao";
      commonName = config.networking.hostName;
      port = 13000;
      interfaces = [ "ens3" ];
      endpoints = [
        { serialNumber = "0"; addressFamily = "ip4"; }
        { serialNumber = "1"; addressFamily = "ip6"; }
      ];
    };
  };

}
