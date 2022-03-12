{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./services.nix
    self.nixosModules.bgp
    self.nixosModules.vultr
    self.nixosModules.gravity
    self.nixosModules.divi
    self.nixosModules.ss
    self.nixosModules.cloud.common
    self.nixosModules.cloud.services
    {
      nixpkgs.overlays = [
        self.overlays.default
        inputs.fn.overlay
        inputs.blog.overlays.default
        inputs.rust-overlay.overlay
      ];
    }
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];
}
