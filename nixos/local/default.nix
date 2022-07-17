{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./hardware.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlays.default
        (final: prev: {
          ranet = inputs.ranet.packages.${system}.default;
          bird = prev.bird-babel-rtt;
          resign = inputs.resign.packages.${system}.default;
        })
      ];
      nix.settings.nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
      nix.registry.p.flake = self;
    }
  ];
}
