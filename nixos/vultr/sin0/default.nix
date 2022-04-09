{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    self.nixosModules.bgp
    self.nixosModules.vultr
    self.nixosModules.divi
    self.nixosModules.v2ray
    self.nixosModules.cloud.common
    self.nixosModules.cloud.services
    {
      nixpkgs.overlays = [
        self.overlays.default
      ];
    }
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];
}
