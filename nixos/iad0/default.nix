{ pkgs, modulesPath, self, inputs, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    ./knot.nix
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  nixpkgs.overlays = [ self.overlays.default ];

  boot = {
    loader.grub.device = "/dev/sda";
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sr_mod" ];
  };

  environment.persistence."/persist" = {
    files = [
      "/var/lib/sops.key"
    ];
    directories = [
      "/var/log"
      "/var/lib/systemd"
      "/var/lib/knot"
    ];
  };

  networking = {
    hostName = "iad0";
    domain = "nichi.link";
    useDHCP = false;
    useNetworkd = true;
    interfaces.enp1s0 = {
      useDHCP = true;
      ipv6.addresses = [{ address = ((import ../../zones/common.nix).nodes.iad0.ipv6); prefixLength = 64; }];
      ipv6.routes = [{ address = "::"; prefixLength = 0; via = "fe80::1"; }];
    };
  };

  services.openssh.enable = true;
  services.sshcert.enable = true;

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
