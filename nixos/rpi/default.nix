{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    inputs.sops-nix.nixosModules.sops
    { nixpkgs.overlays = [ self.overlays.default ]; }
  ];
}
