{
  nixpkgs,
  inputs,
  self,
  ...
}:

nixpkgs.lib.nixosSystem {
  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    {
      nixpkgs.overlays = [ self.overlays.default ];
    }
  ];

  specialArgs = {
    inherit inputs;
  };
}
