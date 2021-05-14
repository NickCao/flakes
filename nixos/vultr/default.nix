{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./image.nix
    {
      nixpkgs.overlays = [
        self.overlay
      ];
    }
  ];
}
