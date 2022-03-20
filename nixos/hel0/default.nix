{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    ./prometheus.nix
    ./matrix.nix
    self.nixosModules.default
    self.nixosModules.cloud.services
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: {
          carinae = inputs.carinae.packages."${system}".default;
          canopus = inputs.canopus.packages."${system}".default;
          nixpkgs = inputs.nixpkgs;
        })
        inputs.rust-overlay.overlay
        inputs.fn.overlay
        self.overlays.default
      ];
    }
  ];
}
