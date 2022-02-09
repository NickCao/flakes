{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.vultr
    self.nixosModules.telegraf
    self.nixosModules.ss
    self.nixosModules.cloud.common
    self.nixosModules.cloud.services
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ({ pkgs, config, ... }: {
      nixpkgs.overlays = [ self.overlay ];
      networking.hostName = "sea0";
      services.dns.secondary.enable = true;
    })
  ];
}
