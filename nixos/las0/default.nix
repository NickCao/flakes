{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    self.nixosModules.buyvm
    self.nixosModules.dns
    self.nixosModules.telegraf
    self.nixosModules.cloud.common
    {
      nixpkgs.overlays = [
        self.overlay
      ];
    }
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];
}
