{ pkgs, config, modulesPath, self, inputs, ... }: {

  sops.secrets = {
    hydra = { group = "hydra"; mode = "0440"; };
    hydra-github = { group = "hydra"; mode = "0440"; };
    plct = { owner = "hydra-queue-runner"; };
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

  services.postgresql = {
    package = pkgs.postgresql_15;
    # TODO: optimize for performance
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

}
