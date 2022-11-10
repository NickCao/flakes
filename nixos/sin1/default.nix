{ pkgs, config, modulesPath, self, inputs, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.impermanence.nixosModules.impermanence
  ];

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
    useDHCP = true;
  };

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
