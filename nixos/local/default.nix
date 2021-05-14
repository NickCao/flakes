{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./hardware.nix
    ../modules/gravity.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlay
        inputs.neovim.overlay
        inputs.rust-overlay.overlay
      ];
      nix.registry.p.flake = self;
    }
  ];
}
