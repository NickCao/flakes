{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    self.nixosModules.vultr
    self.nixosModules.v2ray
    self.nixosModules.cloud.common
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ({ pkgs, config, ... }: {
      nixpkgs.overlays = [ self.overlays.default ];
      networking.hostName = "sea0";
      services.dns.secondary.enable = true;
    })
  ];
}
