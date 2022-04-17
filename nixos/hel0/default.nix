{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    ./prometheus.nix
    ./matrix.nix
    ./maddy.nix
    ./git.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: {
          carinae = inputs.carinae.packages."${system}".default;
          canopus = inputs.canopus.packages."${system}".default;
          nixpkgs = inputs.nixpkgs;
        })
        inputs.fn.overlays.default
        self.overlays.default
      ];
    }
  ];
}
