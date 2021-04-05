{ system, self, nixpkgs, impermanence, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlay
        (final: prev: {
          inputs = {
            inherit self nixpkgs impermanence;
          };
        })
      ];
    }
  ];
}
