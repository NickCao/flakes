{
  description = "a nix derivation collection by nickcao";
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "";
      inputs.home-manager.follows = "";
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
      url = "github:nix-community/dns.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    ranet-ipsec = {
      url = "github:NickCao/ranet";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    colmena = {
      url = "github:nix-community/colmena";
      inputs.stable.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit.follows = "";
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
    jetpack = {
      url = "github:NickCao/jetpack-nixos/master";
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
      ca = ''
        -----BEGIN CERTIFICATE-----
        MIIB4DCCAYegAwIBAgIRAJcwTG2ONvZSkBUK5BaV+t0wCgYIKoZIzj0EAwIwOjEX
        MBUGA1UEChMOTmljaGkgWW9yb3p1eWExHzAdBgNVBAMTFk5pY2hpIFlvcm96dXlh
        IFJvb3QgQ0EwHhcNMjYwOTE3MDI0NjE5WhcNMzYwOTE0MDI0NjE5WjBCMRcwFQYD
        VQQKEw5OaWNoaSBZb3JvenV5YTEnMCUGA1UEAxMeTmljaGkgWW9yb3p1eWEgSW50
        ZXJtZWRpYXRlIENBMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEsP6Ndy2m23x8
        /TYQ21n5jRv6tG2Yih8Pp02Qm8MXHzDR4Fxnm9hRUA2iaNVRRRxyb9QmVoW6UNnY
        WB5FE59EW6NmMGQwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAw
        HQYDVR0OBBYEFI4+Bt14wcFXkgkR+bFbTMVTCnhzMB8GA1UdIwQYMBaAFP+wQMNW
        k50Tqg/a+TYZwI6chbJmMAoGCCqGSM49BAMCA0cAMEQCIGWQ3V8qwGvZ1nO9HrqE
        mfPXWjzSj7qCroqjOwJwelzAAiAOrT0NL8I+bkvKxazWl/hxsZ/F5Nof6s1U1qyf
        x4n/lw==
        -----END CERTIFICATE-----
      '';
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
                sops
                age
                age-plugin-tpm
                colmena
                mdbook
                docker-compose
                ninja
                (opentofu.withPlugins (
                  ps: with ps; [
                    vultr_vultr
                    carlpett_sops
                    hetznercloud_hcloud
                    keycloak_keycloak
                    scaleway_scaleway
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
          inherit self nixpkgs inputs;
        };
        subframe = import ./nixos/subframe {
          inherit self nixpkgs inputs;
        };
        armchair = import ./nixos/armchair {
          inherit
            self
            nixpkgs
            inputs
            ca
            ;
        };
        jetson = import ./nixos/jetson {
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
              data.nameservers = data.nameservers.value;
              data.secondary_nameservers = data.secondary_nameservers.value;
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
                [
                  ./nixos/vultr/common.nix
                  { networking.hostName = name; }
                  (
                    if (builtins.elem "uefi" value.tags) then
                      self.nixosModules.cloud.disko-uefi
                    else
                      self.nixosModules.cloud.disko
                  )
                ]
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
