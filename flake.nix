{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, home-manager, sops-nix }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlay ];
          };
        in
        rec {
          packages = (import ./pkgs).getPackages pkgs;
          checks = packages;
        }) // rec {
      overlay = (import ./pkgs).overlay;
      nixosConfigurations.local = import ./nixos {
        system = "x86_64-linux";
        inherit self nixpkgs home-manager sops-nix;
      };
      pkgs = nixosConfigurations.local.pkgs;
    };
}
