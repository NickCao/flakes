{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blog = {
      url = "gitlab:NickCao/blog";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    fn = {
      url = "gitlab:NickCao/fn";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-compat.follows = "flake-compat";
      inputs.utils.follows = "flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.flake-compat.follows = "flake-compat";
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
          packages = this.packages pkgs // { deploy-rs = deploy-rs.packages.${system}.deploy-rs; };
          checks = packages // (deploy-rs.lib.${system}.deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
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
        rpi = import ./nixos/rpi { system = "aarch64-linux"; inherit self nixpkgs inputs; };
        nrt = import ./nixos/nrt { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        sin = import ./nixos/sin { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        las0 = import ./nixos/las0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      };
      deploy.nodes = {
        # rpi = {
        #   sshUser = "root";
        #   hostname = "10.0.1.2";
        #   profiles = {
        #     system = {
        #       path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.rpi;
        #     };
        #   };
        # };
        nrt = {
          sshUser = "root";
          hostname = "nrt.jp.nichi.link";
          profiles = {
            system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nrt;
            };
          };
        };
        sin = {
          sshUser = "root";
          hostname = "sin.sg.nichi.link";
          profiles = {
            system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.sin;
            };
          };
        };
        las0 = {
          sshUser = "root";
          hostname = "las0.nichi.link";
          profiles = {
            system = {
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.las0;
            };
          };
        };
      };
    };
}
