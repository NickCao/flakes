{ config, pkgs, self, inputs, data, ... }:
let
  hasTag = tag: builtins.elem tag config.deployment.tags;
  prefix = data.nodes."${config.networking.hostName}".prefix;
in
{

  imports = [
    self.nixosModules.vultr
    self.nixosModules.cloud.common
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  services.dns.secondary.enable = hasTag "nameserver";

  nixpkgs.overlays = [
    self.overlays.default
    inputs.fn.overlays.default
    (_final: prev: {
      ranet = inputs.ranet.packages.${pkgs.system}.default;
      bird = prev.bird-babel-rtt;
    })
  ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:${prefix}0::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:${prefix}0::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:${prefix}4:0:4::/96";
    };
    srv6 = {
      enable = true;
      prefix = "2a0c:b641:69c:${prefix}";
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
