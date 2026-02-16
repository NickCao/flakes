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
    ./filesystem.nix
    ./gravity.nix
    ./services.nix
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    {
      nixpkgs.overlays = [ self.overlays.default ];
    }
  ];

  specialArgs = {
    inherit inputs;
  };
}
