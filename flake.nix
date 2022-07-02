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
    fn = {
      url = "gitlab:NickCao/fn";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
      inputs.flake-compat.follows = "flake-compat";
      inputs.utils.follows = "flake-utils";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.utils.follows = "flake-utils";
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
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, dns, ... }:
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
              inputs.deploy-rs.overlay
              inputs.terrasops.overlay
            ];
          };
        in
        rec {
          formatter = pkgs.nixpkgs-fmt;
          packages = this.packages pkgs // {
            inherit (pkgs.deploy-rs) deploy-rs;
            inherit (pkgs) terrasops;
            inherit (pkgs) "db.co.nichi" "db.link.nichi" "db.link.scp";
          };
          checks = packages // (inputs.deploy-rs.lib."${system}".deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
          legacyPackages = pkgs;
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [ deploy-rs.deploy-rs mdbook terrasops ];
          };
        }
      )
    // {
      hydraJobs = self.packages.x86_64-linux // nixpkgs.lib.mapAttrs (_: v: v.config.system.build.toplevel)
        (nixpkgs.lib.filterAttrs (_: v: v.pkgs.system == "x86_64-linux") self.nixosConfigurations) // {
        runCommandHook = with self.legacyPackages.x86_64-linux; {
          test = writeShellScript "test" ''
            ${jq}/bin/jq . "$HYDRA_JSON"
          '';
        };
      };
      nixosModules = import ./modules;
      overlays.default = final: prev: (nixpkgs.lib.composeExtensions this.overlay
        (final: prev: {
          "db.co.nichi" = final.writeText "db.co.nichi" (import ./zones/nichi.co.nix { inherit dns; });
          "db.link.nichi" = final.writeText "db.link.nichi" (import ./zones/nichi.link.nix { inherit dns; });
          "db.link.scp" = final.writeText "db.link.scp" (import ./zones/scp.link.nix { inherit dns; });
        })
        final
        prev);
      nixosConfigurations = {
        local = import ./nixos/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        vultr = import ./nixos/vultr { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        rpi = import ./nixos/rpi { system = "aarch64-linux"; inherit self nixpkgs inputs; };
        nrt0 = import ./nixos/vultr/nrt0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        sin0 = import ./nixos/vultr/sin0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        sea0 = import ./nixos/vultr/sea0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        hel0 = import ./nixos/hel0 { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      };
      deploy.nodes = {
        rpi = {
          sshUser = "root";
          sshOpts = [ "-p" "8122" "-4" "-o" "StrictHostKeyChecking=no" ];
          hostname = "rpi.nichi.link";
          profiles.system.path = inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.rpi;
        };
      } //
      (builtins.listToAttrs (builtins.map
        (name: {
          inherit name;
          value = {
            sshUser = "root";
            sshOpts = [
              "-o GlobalKnownHostsFile=${builtins.toFile "known_hosts" ''
                @cert-authority *.nichi.link ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEe0p7erHjrkNKcY/Kp6fvZtxLcl0hVMVMQPhQrPDZKp
              ''}"
            ];
            hostname = "${name}.nichi.link";
            profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
          };
        }) [ "nrt0" "sin0" "sea0" "hel0" ]));
    };
}
