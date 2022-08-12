{ config, pkgs, lib, self, inputs, ... }: {

  imports = [
    self.nixosModules.vultr
    self.nixosModules.v2ray
    self.nixosModules.cloud.common
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  nixpkgs.overlays = [
    self.overlays.default
    inputs.fn.overlays.default
    (final: prev: {
      ranet = inputs.ranet.packages.${pkgs.system}.default;
      bird = prev.bird-babel-rtt;
    })
  ];

}
