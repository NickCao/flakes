{
  system,
  nixpkgs,
  inputs,
  ...
}:

nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    ./configuration.nix
    ./hardware-configuration.nix
    (inputs.nixos-apple-silicon.nixosModules.apple-silicon-support)
  ];

  specialArgs = {
    inherit inputs;
  };
}
