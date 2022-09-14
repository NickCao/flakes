{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    fn = {
      url = "gitlab:NickCao/fn";
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
            config = {
              allowUnfree = true;
              allowUnsupportedSystem = true;
            };
            overlays = [
              self.overlays.default
              inputs.fn.overlays.default
              inputs.terrasops.overlay
              inputs.sops-nix.overlay
            ];
          };
        in
        rec {
          formatter = pkgs.nixpkgs-fmt;
          packages = this.packages pkgs // {
            inherit (pkgs) terrasops sops-install-secrets;
          };
          legacyPackages = pkgs;
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [ colmena mdbook terrasops nvfetcher ];
          };
        }
      )
    // {
      hydraJobs = self.packages.x86_64-linux //
      inputs.nixpkgs.lib.genAttrs [ "nrt0" "sin0" "sea0" ] (name: (nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self inputs; };
        modules = [ ./nixos/vultr/${name} ];
      }).config.system.build.install) // {
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
        iad0 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./nixos/iad0 ];
          specialArgs = { inherit self inputs; };
        };
      };
      colmena = {
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
      });
    };
}
