{
  description = "a nix derivation collection by nickcao";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (sys:
      let
        pkgs = import nixpkgs {
          system = sys;
          config = { allowUnfree = true; };
        };
      in {
        packages = rec {
          auth-thu = pkgs.callPackage ./pkgs/auth-thu { };
          qv2ray = pkgs.callPackage ./pkgs/qv2ray { };
          v2ray-core = pkgs.callPackage ./pkgs/v2ray-core { };
        };
      });
}
