{ config, ... }: {

  imports = [ ../common.nix ];

  networking.hostName = "fra0";

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:38c0::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:38c0::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:38c4:0:4::/96";
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
