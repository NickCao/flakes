{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    {
      nixpkgs.overlays = [
        self.overlays.default
      ];
    }
    self.nixosModules.cloud.common
    self.nixosModules.vultr
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModule
  ];
}
