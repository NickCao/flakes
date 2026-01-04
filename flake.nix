{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dns = {
      url = "github:nix-community/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    ranet = {
      url = "github:NickCao/ranet/wireguard";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    ranet-ipsec = {
      url = "github:NickCao/ranet";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bouncer = {
      url = "github:NickCao/bouncer";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      data = builtins.fromJSON (builtins.readFile ./zones/data.json);
      lib = inputs.nixpkgs.lib;
    in
    flake-utils.lib.eachSystem
      [
        "aarch64-linux"
        "x86_64-linux"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              inputs.colmena.overlay
            ];
          };
        in
        {
          formatter = pkgs.nixpkgs-fmt;
          legacyPackages = pkgs;
          devShells.default =
            with pkgs;
            mkShell {
              nativeBuildInputs = [
                colmena
                mdbook
                nvfetcher
                (opentofu.withPlugins (
                  ps: with ps; [
                    vultr_vultr
                    carlpett_sops
                    hetznercloud_hcloud
                    keycloak_keycloak
                  ]
                ))
              ];
            };
        }
      )
    // {
      nixosModules = import ./modules;
      overlays.default =
        final: prev:
        prev.lib.packagesFromDirectoryRecursive {
          inherit (prev) callPackage;
          directory = ./pkgs;
        };
      nixosConfigurations = {
        mainframe = import ./nixos/mainframe {
          system = "x86_64-linux";
          inherit self nixpkgs inputs;
        };
        subframe = import ./nixos/subframe {
          system = "aarch64-linux";
          inherit self nixpkgs inputs;
        };
        armchair = import ./nixos/armchair {
          system = "aarch64-linux";
          inherit self nixpkgs inputs;
        };
      }
      // self.colmenaHive.nodes;
      colmenaHive = inputs.colmena.lib.makeHive (
        {
          meta = {
            specialArgs = {
              inherit self inputs;
              data.nodes = data.nodes.value;
              data.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
                "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAICKH4SwgJUkebLaYlrPsNDtnTNtoGRi3Qp/L6POetgySAAAACnNzaDptYXN0ZXI="
              ];
            };
            nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
          };
        }
        // (lib.mapAttrs (
          name: value:
          { ... }:
          {
            deployment = {
              targetHost = "${name}.nichi.link";
              tags = value.tags;
            };
            imports =
              if (builtins.elem "vultr" value.tags) then
                (
                  lib.optionals (builtins.pathExists ./nixos/vultr/${name}) [ ./nixos/vultr/${name} ]
                  ++ [
                    ./nixos/vultr/common.nix
                    { networking.hostName = name; }
                    (
                      if (builtins.elem "uefi" value.tags) then
                        self.nixosModules.cloud.disko-uefi
                      else
                        self.nixosModules.cloud.disko
                    )
                  ]
                )
              else if (builtins.elem "hetzner" value.tags) then
                [
                  ./nixos/hcloud/${name}
                  { networking.hostName = name; }
                ]
              else
                [ ./nixos/${name} ];
          }
        ) data.nodes.value)
      );
    };
}
