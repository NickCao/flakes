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
    self.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    inputs.jetpack.nixosModules.default
  ];
}
