{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.cloud.common
    self.nixosModules.vultr
    inputs.impermanence.nixosModules.impermanence
  ];
}
