{ self, inputs, ... }:
{
  imports = [
    ./configuration.nix
    inputs.sops-nix.nixosModules.sops
    { nixpkgs.overlays = [ self.overlays.default ]; }
  ];
}
