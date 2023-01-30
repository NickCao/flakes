{ pkgs, lib, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  networking = {
    hostName = "hydra";
    domain = "nichi.link";
  };

  services.openssh.enable = true;
  # services.gateway.enable = true;
  # services.metrics.enable = true;

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  environment.baseline.enable = true;

  system.stateVersion = "23.05";

  system.activationScripts.specialfs = lib.mkForce "";

}
