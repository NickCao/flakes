{ pkgs, self, inputs, ... }:
{

  imports = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.overlays = [
    (final: prev: {
      canopus = inputs.canopus.packages."${pkgs.system}".default;
      nixpkgs = inputs.nixpkgs;
    })
    inputs.fn.overlays.default
    self.overlays.default
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      canopus = { };
    };
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

}
