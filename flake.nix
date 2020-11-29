{
  description = "a nix derivation collection by nickcao";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs, flake-utils }:
    let
      genPkgs = val:
        with builtins;
        listToAttrs (map (name: {
          inherit name;
          value = val name;
        }) (attrNames (readDir ./pkgs)));
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [ self.overlay ];
        };
      in { packages = genPkgs (name: pkgs.${name}); }) // {
        overlay = final: prev:
          genPkgs (name: final.callPackage (./pkgs + "/${name}") { });
      };
}
