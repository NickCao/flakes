{ system, self, nixpkgs, impermanence, neovim, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [ self.overlay neovim.overlay ];
      nix.registry.p.flake = nixpkgs;
      home-manager.users.nickcao.imports = [ "${impermanence}/home-manager.nix" ];
    }
  ];
}
