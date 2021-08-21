{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
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
    dns = {
      url = "github:kirelagin/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, dns, ... }:
    let
      this = import ./pkgs;
    in
    flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; overlays = [ self.overlay inputs.deploy-rs.overlay inputs.rust-overlay.overlay inputs.fn.overlay ]; };
        in
        rec {
          packages = this.packages pkgs // {
            deploy-rs = pkgs.deploy-rs.deploy-rs;
            inherit (pkgs) "db.co.nichi" "db.link.nichi";
          };
          checks = packages // (inputs.deploy-rs.lib.${system}.deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
          legacyPackages = pkgs;
          devShell = with pkgs; mkShell {
            nativeBuildInputs = [ deploy-rs.deploy-rs ];
          };
        }
      )
    // {
      nixosModules = import ./modules;
      overlay = final: prev: (nixpkgs.lib.composeExtensions this.overlay
        (final: prev: {
          "db.co.nichi" = final.writeText "db.co.nichi" (import ./zones/nichi.co.nix { inherit dns; });
          "db.link.nichi" = final.writeText "db.link.nichi" (import ./zones/nichi.link.nix { inherit dns; });
        })
        final
        prev);
      nixosConfigurations = {
        local = import ./nixos/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        vultr = import ./nixos/vultr { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        rpi = import ./nixos/rpi { system = "aarch64-linux"; inherit self nixpkgs inputs; };
        nrt0 = import ./nixos/nrt0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        sin0 = import ./nixos/sin0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        las0 = import ./nixos/las0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      };
      deploy.nodes = {
        rpi = {
          sshUser = "root";
          hostname = "10.0.1.2";
          profiles.system.path = inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.rpi;
        };
        nrt0 = {
          sshUser = "root";
          hostname = "nrt0.nichi.link";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nrt0;
        };
        sin0 = {
          sshUser = "root";
          hostname = "sin0.nichi.link";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.sin0;
        };
        las0 = {
          sshUser = "root";
          hostname = "las0.nichi.link";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.las0;
        };
      };
    };
}
