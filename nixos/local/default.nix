{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./hardware.nix
    self.nixosModules.gravity
    self.nixosModules.kernel
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.bootspec.nixosModules.bootspec
    {
      nixpkgs.overlays = [
        self.overlay
        inputs.rust-overlay.overlay
        (final: prev: {
          smartdns = prev.smartdns.overrideAttrs (attrs: {
            postPatch = "rm systemd/smartdns.service";
          });
        })
      ];
      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      nix.registry.p.flake = self;
    }
  ];
}
