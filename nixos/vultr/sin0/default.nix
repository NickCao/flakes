{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    self.nixosModules.bgp
    self.nixosModules.vultr
    self.nixosModules.gravity
    self.nixosModules.divi
    self.nixosModules.dns
    self.nixosModules.telegraf
    self.nixosModules.ss
    self.nixosModules.cloud.common
    self.nixosModules.cloud.cluster
    {
      nixpkgs.overlays = [
        self.overlay
      ];
    }
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];
}
