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
      hydra = { group = "hydra"; mode = "0440"; };
      cache = { group = "hydra"; mode = "0440"; };
      github = { group = "hydra"; mode = "0440"; };
      plct = { owner = "hydra-queue-runner"; };
      minio.restartUnits = [ "minio.service" ];
      telegraf.restartUnits = [ "telegraf.service" ];
      nixbot.restartUnits = [ "nixbot.service" ];
      meow.restartUnits = [ "meow.service" ];
      dkim.restartUnits = [ "maddy.service" ];
      "hercules/cluster-join-token.key" = {
        owner = "hercules-ci-agent";
        restartUnits = [ "hercules-ci-agent.service" ];
      };
      "hercules/binary-caches.json" = {
        owner = "hercules-ci-agent";
        restartUnits = [ "hercules-ci-agent.service" ];
      };
      "hercules/secrets.json" = {
        owner = "hercules-ci-agent";
        restartUnits = [ "hercules-ci-agent.service" ];
      };
    };
  };

  systemd.services.hydra-queue-runner.serviceConfig.EnvironmentFile = [ config.sops.secrets.hydra.path ];
  services.hydra = {
    enable = true;
    listenHost = "127.0.0.1";
    hydraURL = "https://hydra.nichi.co/";
    useSubstitutes = true;
    notificationSender = "hydra@nichi.co";
    buildMachinesFiles = [ "/etc/nix/machines" ];
    extraConfig = ''
      store_uri = s3://cache?secret-key=${config.sops.secrets.cache.path}&region=us-east-1&endpoint=s3.nichi.co&write-nar-listing=1&ls-compression=br&log-compression=br
      server_store_uri = https://s3.nichi.co/cache
      binary_cache_public_uri = https://s3.nichi.co/cache
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)}
      github_client_id = e55d265b1883eb42630e
      github_client_secret_file = ${config.sops.secrets.github.path}
    '';
  };

  services.hercules-ci-agent = {
    enable = true;
    settings = {
      staticSecretsDirectory = "/run/secrets/hercules";
    };
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

  security.wrappers.smartctl = {
    owner = "root";
    group = "root";
    setuid = true;
    setgid = true;
    source = "${pkgs.smartmontools}/bin/smartctl";
  };
  services.telegraf = {
    enable = true;
    environmentFiles = [ config.sops.secrets.telegraf.path ];
    extraConfig = {
      outputs = {
        influxdb_v2 = {
          urls = [ "https://stats.nichi.co" ];
          token = "$INFLUX_TOKEN";
          organization = "nichi";
          bucket = "stats";
        };
      };
      inputs = {
        cpu = { };
        disk = { };
        diskio = { };
        mem = { };
        net = { };
        system = { };
        smart = {
          path_smartctl = "${config.security.wrapperDir}/smartctl";
          path_nvme = "${pkgs.nvme-cli}/bin/nvme";
          devices = [ "/dev/disk/by-id/wwn-0x50000397fc5003aa -d ata" "/dev/disk/by-id/wwn-0x500003981ba001ae -d ata" ];
        };
      };
    };
  };

  services.minio = {
    enable = true;
    browser = false;
    listenAddress = "127.0.0.1:9000";
    rootCredentialsFile = config.sops.secrets.minio.path;
  };

  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "127.0.0.1:8086";
    };
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

  services.etcd = {
    enable = true;
    name = config.networking.hostName;
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      experimental.http3 = true;
      entryPoints = {
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
            permanent = false;
          };
        };
        https = {
          address = ":443";
          http.tls.certResolver = "le";
          enableHTTP3 = true;
        };
        imap = {
          address = ":993";
          http.tls.certResolver = "le";
        };
        submission = {
          address = ":465";
          http.tls.certResolver = "le";
        };
      };
      certificatesResolvers.le.acme = {
        email = "blackhole@nichi.co";
        storage = config.services.traefik.dataDir + "/acme.json";
        keyType = "EC256";
        tlsChallenge = { };
      };
      ping = {
        manualRouting = true;
      };
    };
    dynamicConfigOptions = {
      tls.options.default = {
        minVersion = "VersionTLS12";
        sniStrict = true;
      };
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
          etcd = {
            rule = "HostSNI(`etcd.nichi.co`)";
            entryPoints = [ "https" ];
            service = "etcd";
            tls = { };
          };
        };
        services = {
          imap.loadBalancer.servers = [{ address = "127.0.0.1:143"; }];
          submission.loadBalancer.servers = [{ address = "127.0.0.1:587"; }];
          etcd.loadBalancer.servers = [{ address = "127.0.0.1:2379"; }];
        };
      };
      http = {
        routers = {
          ping = {
            rule = "Host(`hel0.nichi.link`)";
            entryPoints = [ "https" ];
            service = "ping@internal";
          };
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
          influx = {
            rule = "Host(`stats.nichi.co`)";
            entryPoints = [ "https" ];
            service = "influx";
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
          influx.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://${config.services.influxdb2.settings.http-bind-address}"; }];
          };
          tagging.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:19000"; }];
          };
          hydra.loadBalancer = {
            passHostHeader = true;
            servers = [{ url = "http://127.0.0.1:3000"; }];
          };
        };
      };
    };
  };
}
