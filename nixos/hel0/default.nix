{ pkgs, self, inputs, ... }:
{
  imports = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    ./matrix.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: {
          canopus = inputs.canopus.packages."${pkgs.system}".default;
          nixpkgs = inputs.nixpkgs;
        })
        inputs.fn.overlays.default
        self.overlays.default
      ];
    }
  ];
}
