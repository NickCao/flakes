{
  description = "a nix derivation collection by nickcao";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, flake-utils }:
    let
      getPackages = val:
        with builtins;
        listToAttrs (map
          (name: {
            inherit name;
            value = val name;
          })
          (attrNames (readDir ./pkgs)));
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
            };
            overlays =
              [ self.overlay (final: prev: prev.prefer-remote-fetch final prev) ];
          };
        in
        rec {
          packages = pkgs.lib.filterAttrs (n: p: p.meta.only or true) (getPackages (name: pkgs.${name}));
          checks = packages;
        }) // {
      overlay = final: prev:
        getPackages (name: final.callPackage (./pkgs + "/${name}") { }) // { pam = prev.pam.overrideAttrs (attrs: { patches = [ ]; }); };
    };
}
