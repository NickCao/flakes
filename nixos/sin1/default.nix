{ pkgs, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ./pb.nix
    ./misc.nix
  ];

  nixpkgs.overlays = [
    self.overlays.default
    inputs.fn.overlays.default
  ];

  sops = {
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

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/persist" ];
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
  services.gateway.enable = true;
  services.metrics.enable = true;

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  environment.baseline.enable = true;

  system.stateVersion = "22.05";

}
