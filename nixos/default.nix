{ self, nixpkgs, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    { nixpkgs.overlays = [ self.overlay ]; }
  ];
}
