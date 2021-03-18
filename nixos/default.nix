{ system, self, nixpkgs, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlay
        (final: prev: {
          f = self;
        })
      ];
    }
  ];
}
