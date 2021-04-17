{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/gnome-40";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let this = import ./pkgs; in
    nixpkgs.lib.recursiveUpdate
      (flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlay ]; };
        in
        rec {
          packages = this.packages pkgs;
          checks = packages;
          legacyPackages = pkgs;
        }
      ))
      ({
        overlay = this.overlay;
        nixosConfigurations.local = import ./nixos { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      });
}
