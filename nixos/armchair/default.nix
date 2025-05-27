{
  system,
  nixpkgs,
  inputs,
  self,
  ...
}:

nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
  ];

  specialArgs = {
    inherit inputs;
  };
}
