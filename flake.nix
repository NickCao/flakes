{
  description = "a nix derivation collection by nickcao";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };
      in {
        packages = {
          auth-thu = pkgs.callPackage ./pkgs/auth-thu { };
          qv2ray = pkgs.callPackage ./pkgs/qv2ray { };
          v2ray-core = pkgs.callPackage ./pkgs/v2ray-core { };
          rait = pkgs.callPackage ./pkgs/rait { };
          smartdns-china-list = pkgs.callPackage ./pkgs/smartdns-china-list { };
        };
      }) // {
        overlay = final: prev: {
          auth-thu = prev.callPackage ./pkgs/auth-thu { };
          qv2ray = prev.callPackage ./pkgs/qv2ray { };
          v2ray-core = prev.callPackage ./pkgs/v2ray-core { };
          rait = prev.callPackage ./pkgs/rait { };
          smartdns-china-list = prev.callPackage ./pkgs/smartdns-china-list { };
        };
      };
}
