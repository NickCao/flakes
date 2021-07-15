{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.ssh
    self.nixosModules.vultr
    self.nixosModules.image
  ];
}
