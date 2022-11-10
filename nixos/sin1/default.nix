{ pkgs, config, modulesPath, self, inputs, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    self.nixosModules.default
    self.nixosModules.cloud.filesystems
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  nixpkgs.overlays = [ self.overlays.default ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      hydra = { group = "hydra"; mode = "0440"; };
      hydra-github = { group = "hydra"; mode = "0440"; };
      plct = { owner = "hydra-queue-runner"; };
    };
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

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
      allowed-uris = [ "https://github.com" "https://gitlab.com" ];
    };
    buildMachines = [
      {
        hostName = "k11-plct.nichi.link";
        systems = [ "x86_64-linux" ];
        maxJobs = 32;
        supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
      }
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

  services.postgresql = {
    package = pkgs.postgresql_15;
  };

  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.nichi.co";
    useSubstitutes = true;
    notificationSender = "hydra@nichi.co";
    buildMachinesFiles = [ "/etc/nix/machines" ];
    extraConfig = ''
      include ${config.sops.secrets.hydra.path}
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.hydra-github.path}
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
      <dynamicruncommand>
        enable = 1
      </dynamicruncommand>
      <githubstatus>
        jobs = misc:flakes:.*
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>
    '';
  };

  programs.ssh = {
    knownHosts = {
      "k11-plct.nichi.link".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7Gb+JDMj+P2Wumrvwbr7lCqyl93gy06b8Af9si7Rye";
    };
    extraConfig = ''
      Host k11-plct.nichi.link
        User root
        IdentityFile ${config.sops.secrets.plct.path}
    '';
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          hydra = {
            rule = "Host(`hydra.nichi.co`)";
            entryPoints = [ "https" ];
            service = "hydra";
          };
        };
        services = {
          hydra.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:3000"; }];
          };
        };
      };
    };
  };

  users.users.root.openssh.authorizedKeys.keys = pkgs.keys;

  environment.baseline.enable = true;

  system.stateVersion = "22.05";
}
