{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    { nixpkgs.overlays = [ (final: prev: { inherit (inputs.nixbot.packages.${system}) nixbot-telegram; }) inputs.rust-overlay.overlay inputs.fn.overlay ]; }
  ];
}
