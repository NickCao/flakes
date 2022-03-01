{ config, lib, pkgs, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      matrix = { };
      restic = { };
      backup = { };
      hydra = { group = "hydra"; mode = "0440"; };
      hydra-github = { group = "hydra"; mode = "0440"; };
      cache = { group = "hydra"; mode = "0440"; };
      plct = { owner = "hydra-queue-runner"; };
      minio.restartUnits = [ "minio.service" ];
      nixbot.restartUnits = [ "nixbot.service" ];
      meow.restartUnits = [ "meow.service" ];
      dkim.restartUnits = [ "maddy.service" ];
      vault = { };
      tsig = { sopsFile = ../../modules/dns/secondary/secrets.yaml; owner = "knot"; };
      gravity = { owner = "knot"; };
      gravity_reverse = { owner = "knot"; };
    };
  };

  services.gateway.enable = true;
  services.sshcert.enable = true;
  services.metrics.enable = true;

  services.postgresql.authentication = ''
    local dendrite dendrite peer
  '';
  systemd.services.dendrite.serviceConfig.LoadCredential = "matrix:${config.sops.secrets.matrix.path}";
  services.dendrite = {
    enable = true;
    httpAddress = "127.0.0.1:8008";
    settings = {
      global = {
        server_name = "nichi.co";
        private_key = "/$CREDENTIALS_DIRECTORY/matrix";
        metrics.enable = true;
      };
      app_service_api = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
      };
      client_api = {
        registration_disabled = true;
      };
      media_api = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
        max_file_size_bytes = 10485760;
        dynamic_thumbnails = true;
      };
      room_server = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
      };
      mscs = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
        mscs = [ "msc2836" "msc2946" ];
      };
      sync_api = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
        real_ip_header = "X-Real-IP";
      };
      key_server = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
      };
      federation_api = {
        database.connection_string = "postgres:///dendrite?host=/run/postgresql";
        key_perspectives = [{
          server_name = "matrix.org";
          keys = [
            {
              key_id = "ed25519:auto";
              public_key = "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw";
            }
            {
              key_id = "ed25519:a_RXGa";
              public_key = "l8Hft5qXKn1vfHrg3p4+W8gELQVo8N13JkluMfmn2sQ";
            }
          ];
        }];
      };
      user_api = {
        account_database.connection_string = "postgres:///dendrite?host=/run/postgresql";
        device_database.connection_string = "postgres:///dendrite?host=/run/postgresql";
      };
    };
  };

  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    port = 8004;
    secretKeyFile = config.sops.secrets.cache.path;
  };

  services.knot = {
    enable = true;
    keyFiles = [ config.sops.secrets.tsig.path ];
    extraConfig = builtins.readFile ./knot.conf + ''
      zone:
        - domain: firstparty
          template: catalog
        - domain: nichi.co
          file: ${pkgs."db.co.nichi"}
          dnssec-signing: off
          catalog-role: member
          catalog-zone: firstparty
        - domain: nichi.link
          file: ${pkgs."db.link.nichi"}
          catalog-role: member
          catalog-zone: firstparty
        - domain: scp.link
          file: ${pkgs."db.link.scp"}
          catalog-role: member
          catalog-zone: firstparty
        - domain: gravity
          file: ${config.sops.secrets.gravity.path}
          dnssec-signing: off
          catalog-role: member
          catalog-zone: firstparty
        - domain: 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa
          file: ${config.sops.secrets.gravity_reverse.path}
          catalog-role: member
          catalog-zone: firstparty
    '';
  };

  services.hydra = {
    enable = true;
    package = pkgs.hydra-unstable.override {
      nix = pkgs.nixVersions.unstable.overrideAttrs (_: {
        patches = [
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nix/commit/33603df68144e124edc4f147d1a67884d131f5a4.patch";
            sha256 = "sha256-KJgMcjCjtgTRHxyhfLtKBej5Q9X5RVOEb2dTejJJEYk=";
          })
        ];
      });
    };
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.nichi.co";
    useSubstitutes = true;
    notificationSender = "hydra@nichi.co";
    buildMachinesFiles = [ "/etc/nix/machines" ];
    extraConfig = ''
      include ${config.sops.secrets.hydra.path}
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.hydra-github.path}
      binary_cache_secret_key_file = ${config.sops.secrets.cache.path}
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
      <githubstatus>
        jobs = personal:flakes:.*
        excludeBuildFromContext = 1
        useShortContext = 1
      </githubstatus>
    '';
  };

  services.vaultwarden = {
    enable = true;
    config = {
      signupsAllowed = false;
      sendsAllowed = false;
      emergencyAccessAllowed = false;
      orgCreationUsers = "none";
      domain = "https://vault.nichi.co";
      rocketAddress = "127.0.0.1";
      rocketPort = 8003;
    };
    environmentFile = config.sops.secrets.vault.path;
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.tagging = {
    image = "quay.io/numendacil/test:latest";
    extraOptions = [ "--network=slirp4netns" "--memory=4G" ];
    ports = [ "127.0.0.1:19000:8501" ];
  };

  cloud.services.meow = {
    exec = "${pkgs.meow}/bin/meow";
    envFile = config.sops.secrets.meow.path;
  };

  systemd.services.nixbot = {
    serviceConfig = {
      DynamicUser = true;
      WorkingDirectory = "/tmp";
      PrivateTmp = true;
      Restart = "always";
      LoadCredential = "nixbot:${config.sops.secrets.nixbot.path}";
    };
    script = ''
      exec ${pkgs.nixbot-telegram}/bin/nixbot-telegram ''${CREDENTIALS_DIRECTORY}/nixbot
    '';
    wantedBy = [ "multi-user.target" ];
  };

  services.minio = {
    enable = true;
    browser = false;
    listenAddress = "127.0.0.1:9000";
    rootCredentialsFile = config.sops.secrets.minio.path;
  };

  systemd.packages = [ pkgs.maddy ];
  environment.systemPackages = [ pkgs.maddy ];
  users.users.maddy.isSystemUser = true;
  users.users.maddy.group = "maddy";
  users.groups.maddy = { };
  environment.etc."maddy/maddy.conf".source = ./maddy.conf;
  systemd.services.maddy = {
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ (builtins.hashFile "sha256" ./maddy.conf) ];
    serviceConfig = {
      LoadCredential = [
        "dkim.key:${config.sops.secrets.dkim.path}"
      ];
    };
  };

  services.rtsp-simple-server = {
    enable = true;
    settings = {
      protocols = [ "tcp" ];
      rtspAddress = "127.0.0.1:8554";
      rtmpDisable = true;
      hlsDisable = true;
      paths = {
        all = {
          source = "publisher";
          sourceProtocol = "tcp";
          publishUser = "push";
          publishPass = "sha256:gugzUGZV3BHLO+Kes1GvCeD32CmYV19qHuj9Em7dk6I=";
        };
      };
    };
  };

  services.traefik = {
    staticConfigOptions = {
      entryPoints = {
        imap = {
          address = ":993";
          http.tls.certResolver = "le";
        };
        submission = {
          address = ":465";
          http.tls.certResolver = "le";
        };
        rtsp = {
          address = ":322";
          http.tls.certResolver = "le";
        };
      };
    };
    dynamicConfigOptions = {
      tcp = {
        routers = {
          imap = {
            rule = "HostSNI(`hel0.nichi.link`)";
            entryPoints = [ "imap" ];
            service = "imap";
            tls = { };
          };
          submission = {
            rule = "HostSNI(`hel0.nichi.link`)";
            entryPoints = [ "submission" ];
            service = "submission";
            tls = { };
          };
          rtsp = {
            rule = "HostSNI(`live.nichi.co`)";
            entryPoints = [ "rtsp" ];
            service = "rtsp";
            tls.certResolver = "le";
          };
        };
        services = {
          imap.loadBalancer.servers = [{ address = "127.0.0.1:143"; }];
          submission.loadBalancer.servers = [{ address = "127.0.0.1:587"; }];
          rtsp.loadBalancer.servers = [{ address = "${config.services.rtsp-simple-server.settings.rtspAddress}"; }];
        };
      };
      http = {
        routers = {
          minio = {
            rule = "Host(`s3.nichi.co`)";
            entryPoints = [ "https" ];
            service = "minio";
          };
          meow = {
            rule = "Host(`pb.nichi.co`)";
            entryPoints = [ "https" ];
            service = "meow";
          };
          tagging = {
            rule = "Host(`tagging.nichi.co`)";
            entryPoints = [ "https" ];
            service = "tagging";
            middlewares = [ "compress" ];
          };
          hydra = {
            rule = "Host(`hydra.nichi.co`)";
            entryPoints = [ "https" ];
            service = "hydra";
          };
          vault = {
            rule = "Host(`vault.nichi.co`)";
            entryPoints = [ "https" ];
            service = "vault";
          };
          cache = {
            rule = "Host(`cache.nichi.co`)";
            entryPoints = [ "https" ];
            service = "cache";
          };
          matrix = {
            rule = "Host(`matrix.nichi.co`)";
            entryPoints = [ "https" ];
            service = "dendrite";
          };
        };
        middlewares = {
          compress.compress = { };
        };
        services = {
          minio.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://${config.services.minio.listenAddress}"; }];
          };
          meow.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8002"; }];
          };
          tagging.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:19000"; }];
          };
          hydra.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:3000"; }];
          };
          vault.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:8003"; }];
          };
          cache.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:${builtins.toString config.services.nix-serve.port}"; }];
          };
          dendrite.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://${config.services.dendrite.httpAddress}"; }];
          };
        };
      };
    };
  };
  documentation.nixos.enable = false;
}
