{ pkgs, self, inputs, ... }:
{

  imports = [
    ./configuration.nix
    ./hardware.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.overlays = [ self.overlays.default ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

}
