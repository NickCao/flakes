{ config, pkgs, lib, self, inputs, ... }:
let
  hasTag = tag: builtins.elem tag config.deployment.tags;
in
{

  imports = [
    self.nixosModules.vultr
    self.nixosModules.cloud.common
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  services.dns.secondary.enable = hasTag "nameserver";

  cloud.caddy.enable = true;
  services.gateway.enable = lib.mkForce false;

  nixpkgs.overlays = [
    self.overlays.default
    inputs.fn.overlays.default
    (final: prev: {
      ranet = inputs.ranet.packages.${pkgs.system}.default;
      bird = prev.bird-babel-rtt;
    })
  ];

}
