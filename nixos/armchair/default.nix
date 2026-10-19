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
    ./gravity.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    {
      nixpkgs.overlays = [
        self.overlays.default
      ];
    }
  ];

  specialArgs = {
    inherit inputs;
  };
}
