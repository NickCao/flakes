{
  self,
  nixpkgs,
  inputs,
}:
nixpkgs.lib.nixosSystem {
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./hardware.nix
    self.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.lanzaboote.nixosModules.lanzaboote
    (
      { config, ... }:
      {
        nixpkgs.overlays = [
          self.overlays.default
          (_final: prev: {
            ranet = inputs.ranet.packages.${config.nixpkgs.hostPlatform}.default;
          })
        ];
        nix.settings.nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];
        nix.registry.p.flake = self;
      }
    )
  ];
  specialArgs = {
    inherit inputs;
  };
}
