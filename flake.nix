{
  description = "a nix derivation collection by nickcao";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [ self.overlay ];
        };
      in {
        packages = {
          auth-thu = pkgs.auth-thu;
          qv2ray = pkgs.qv2ray;
          v2ray-core = pkgs.v2ray-core;
          rait = pkgs.rait;
          smartdns-china-list = pkgs.smartdns-china-list;
        };
      }) // {
        overlay = final: prev: {
          auth-thu = final.callPackage ./pkgs/auth-thu { };
          qv2ray = final.callPackage ./pkgs/qv2ray { };
          v2ray-core = final.callPackage ./pkgs/v2ray-core { };
          rait = final.callPackage ./pkgs/rait { };
          smartdns-china-list = final.callPackage ./pkgs/smartdns-china-list { };
        };
      };
}
