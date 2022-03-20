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
    inputs.bootspec.nixosModules.bootspec
    {
      nixpkgs.overlays = [
        self.overlays.default
        inputs.rust-overlay.overlay
        inputs.matlab.overlay
      ];
      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      nix.registry.p.flake = self;
    }
  ];
}
