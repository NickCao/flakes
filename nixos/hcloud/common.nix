{ pkgs, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nixpkgs.overlays = [
    self.overlays.default
    inputs.fn.overlays.default
  ];

  boot = {
    loader.grub.device = "/dev/sda";
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sr_mod" ];
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

  systemd.services.restic-backups-persist = {
    serviceConfig.Environment = [ "GOGC=20" ];
  };

  services.restic.backups.persist = {
    repository = "sftp:backup:backup";
    passwordFile = config.sops.secrets.restic.path;
    paths = [ "/persist" ];
    timerConfig = {
      OnCalendar = "daily";
    };
  };

  networking = {
    domain = "nichi.link";
    useDHCP = false;
    useNetworkd = true;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [{ address = data.nodes.${config.networking.hostName}.ipv6; prefixLength = 64; }];
      ipv6.routes = [{ address = "::"; prefixLength = 0; via = "fe80::1"; }];
    };
  };

  services.openssh.enable = true;
  services.gateway.enable = true;
  services.metrics.enable = true;

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  environment.baseline.enable = true;
  environment.backup.enable = true;

  system.stateVersion = "22.05";

}
