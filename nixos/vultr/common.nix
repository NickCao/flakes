{
  config,
  pkgs,
  self,
  inputs,
  data,
  modulesPath,
  ...
}:
let
  hasTag = tag: builtins.elem tag config.deployment.tags;
  prefix = data.nodes."${config.networking.hostName}".prefix;
in
{

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  sops = {
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  boot = {
    tmp.useTmpfs = true;
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = data.keys;

  cloud.caddy.enable = true;
  services.metrics.enable = true;
  services.openssh.enable = true;

  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "nichi.link";
  };

  systemd.network.networks = {
    ethernet = {
      matchConfig.Name = [
        "en*"
        "eth*"
      ];
      DHCP = "yes";
      networkConfig = {
        KeepConfiguration = "yes";
        IPv6AcceptRA = "yes";
        IPv6PrivacyExtensions = "no";
      };
    };
  };

  environment.persistence."/persist" = {
    files = [ "/etc/machine-id" ];
    directories = [ "/var" ];
  };

  environment.baseline.enable = true;

  services.dns.secondary.enable = hasTag "nameserver";

  nixpkgs.overlays = [
    self.overlays.default
    (_final: prev: {
      ranet = inputs.ranet.packages.${pkgs.stdenv.hostPlatform.system}.default;
    })
  ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:${prefix}0::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      routes = [
        "route 2a0c:b641:69c:${prefix}0::/60 from ::/0 unreachable"
      ];
    };
    divi = {
      enable = true;
      oif = if (hasTag "uefi") then "enp1s0" else "ens3";
      prefix = "2a0c:b641:69c:${prefix}4:0:4::/96";
    };
    srv6 = {
      enable = true;
      prefix = "2a0c:b641:69c:${prefix}";
    };
    ipsec = {
      enable = true;
      organization = "nickcao";
      commonName = config.networking.hostName;
      port = 13000;
      interfaces = if (hasTag "uefi") then [ "enp1s0" ] else [ "ens3" ];
      endpoints = [
        {
          serialNumber = "0";
          addressFamily = "ip4";
        }
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
    };
  };

  system.stateVersion = "24.05";

}
