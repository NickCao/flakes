{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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
  outputs = inputs@{ self, nixpkgs, flake-utils, deploy-rs, ... }:
    let
      this = import ./pkgs;
    in
      flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ]
        (
          system:
            let
              pkgs = import nixpkgs { inherit system; config.allowUnfree = true; overlays = [ self.overlay inputs.rust-overlay.overlay ]; };
            in
              rec {
                packages = this.packages pkgs;
                checks = packages;
                legacyPackages = pkgs;
                devShell = with pkgs; mkShell {
                  nativeBuildInputs = [ deploy-rs.packages.${system}.deploy-rs ];
                };
              }
        )
      // {
        overlay = this.overlay;
        nixosConfigurations = {
          local = import ./nixos/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
          vultr = import ./nixos/vultr { system = "x86_64-linux"; inherit self nixpkgs inputs; };
          testbed = import ./nixos/testbed { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        };
        deploy.nodes.testbed = {
          sshUser = "root";
          hostname = "nixos.nichi.link";
          profiles = {
            system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.testbed;
            };
          };
        };
      };
}
