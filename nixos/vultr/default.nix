{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ../modules/ssh.nix
    ../modules/vultr.nix
    ../modules/image.nix
  ];
}
