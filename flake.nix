{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    fn = {
      url = "github:NickCao/fn";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-22_05.follows = "nixpkgs";
    };
    dns = {
      url = "github:NickCao/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    carinae = {
      url = "github:NickCao/carinae";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    canopus = {
      url = "github:NickCao/canopus";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    ranet = {
      url = "github:SCP-2000/ranet";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    terrasops = {
      url = "github:NickCao/terrasops";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    resign = {
      url = "github:NickCao/resign";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    knot-sys = {
      url = "github:NickCao/knot-sys";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let
      this = import ./pkgs;
    in
    flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              inputs.colmena.overlay
              inputs.terrasops.overlay
            ];
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          packages = this.packages pkgs // {
            inherit (pkgs) terrasops;
          };
          legacyPackages = pkgs;
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [ colmena mdbook terrasops nvfetcher ];
          };
        }
      )
    // {
      hydraJobs = self.packages.x86_64-linux //
      inputs.nixpkgs.lib.genAttrs
        [ "nrt0" "sin0" "sea0" ]
        (name: self.colmenaHive.nodes.${name}.config.system.build.install)
      // {
        local = self.nixosConfigurations.local.config.system.build.toplevel;
      };
      nixosModules = import ./modules;
      overlays.default = final: prev: (nixpkgs.lib.composeExtensions this.overlay
        (final: prev: {
          keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
          ];
        })
        final
        prev);
      nixosConfigurations = {
        local = import ./nixos/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      } // self.colmenaHive.nodes;
      colmenaHive = inputs.colmena.lib.makeHive ({
        meta = {
          specialArgs = {
            inherit self inputs;
          };
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };
        };
        rpi = { ... }: {
          nixpkgs.system = "aarch64-linux";
          deployment = {
            targetHost = "rpi.nichi.link";
            targetPort = 8122;
          };
          imports = [ ./nixos/rpi ];
        };
        hel0 = { ... }: {
          deployment = {
            targetHost = "hel0.nichi.link";
            tags = [ "normal" ];
          };
          imports = [ ./nixos/hel0 ];
        };
        iad0 = { ... }: {
          deployment = {
            targetHost = "iad0.nichi.link";
            tags = [ "normal" ];
          };
          imports = [ ./nixos/iad0 ];
        };
      } // inputs.nixpkgs.lib.genAttrs [ "nrt0" "sin0" "sea0" ] (name: { ... }: {
        deployment = {
          targetHost = "${name}.nichi.link";
          tags = [ "normal" "vultr" ];
        };
        imports = [ ./nixos/vultr/${name} ];
      }));
    };
}
