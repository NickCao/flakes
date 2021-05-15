{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ../modules/vultr.nix
    ../modules/gravity.nix
    ../modules/divi.nix
    {
      nixpkgs.overlays = [
        self.overlay
      ];
    }
    inputs.sops-nix.nixosModules.sops
  ];
}
