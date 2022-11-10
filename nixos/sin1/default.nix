{ pkgs, config, modulesPath, self, inputs, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ./hydra.nix
  ];

  nixpkgs.overlays = [ self.overlays.default ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  boot = {
    loader.grub.device = "/dev/sda";
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" ];
  };

  environment.persistence."/persist" = {
    directories = [
      "/var"
    ];
  };

  networking = {
    hostName = "sin1";
    domain = "nichi.link";
    useDHCP = false;
    useNetworkd = true;
    interfaces.ens18 = {
      useDHCP = true;
      ipv6.addresses = [{ address = "2407:3640:2108:595::1"; prefixLength = 64; }];
      ipv6.routes = [{ address = "::"; prefixLength = 0; via = "fe80::1"; }];
    };
  };

  services.openssh.enable = true;
  services.sshcert.enable = true;
  services.gateway.enable = true;
  services.fstrim.enable = true;

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
