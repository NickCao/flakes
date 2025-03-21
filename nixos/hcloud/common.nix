{
  config,
  lib,
  modulesPath,
  self,
  inputs,
  data,
  ...
}:
{

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.disko
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
  ];

  disko.devices.disk.vda.device = lib.mkForce "/dev/sda";

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nixpkgs.overlays = [ self.overlays.default ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "sd_mod"
      "sr_mod"
    ];
  };

  environment.persistence."/persist" = {
    files = [ "/etc/machine-id" ];
    directories = [ "/var" ];
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/persist" ];
  };

  networking = {
    domain = "nichi.link";
    useDHCP = false;
    useNetworkd = true;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [
        {
          address = data.nodes.${config.networking.hostName}.ipv6;
          prefixLength = 64;
        }
      ];
      ipv6.routes = [
        {
          address = "::";
          prefixLength = 0;
          via = "fe80::1";
        }
      ];
    };
  };

  cloud.caddy.enable = true;
  services.openssh.enable = true;
  services.metrics.enable = true;

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  environment.baseline.enable = true;
  environment.backup.enable = true;

  system.stateVersion = lib.mkDefault "24.05";

}
