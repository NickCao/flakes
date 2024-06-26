{
  config,
  modulesPath,
  data,
  self,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.disko
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  cloud.caddy.enable = true;
  services.metrics.enable = true;
  services.openssh.enable = true;

  boot.tmp.useTmpfs = true;

  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "nichi.link";
  };

  environment.persistence."/persist" = {
    files = [ "/etc/machine-id" ];
    directories = [ "/var" ];
  };

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
