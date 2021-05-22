{ pkgs, config, ... }:
{
  # TODO: force podman to use nftables
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    blog = {
      ports = [ "127.0.0.1::8080" ];
      image = "quay.io/nickcao/blog";
      extraOptions = [ "--label=traefik.http.routers.blog.rule=Host(`nichi.co`)" ];
    };
    meow = {
      ports = [ "127.0.0.1::8080" ];
      image = "quay.io/nickcao/meow";
      environment = {
        BASE_URL = "https://pb.nichi.co";
        S3_BUCKET = "pastebin-nichi";
        S3_ENDPOINT = "https://s3.us-west-000.backblazeb2.com";
      };
      environmentFiles = [ config.sops.secrets.meow.path ];
      extraOptions = [ "--label=traefik.http.routers.meow.rule=Host(`pb.nichi.co`)" ];
    };
    woff = {
      ports = [ "127.0.0.1::8080" ];
      image = "registry.gitlab.com/nickcao/functions/woff";
      environment = {
        RETURN_URL = "https://nichi.co";
      };
      environmentFiles = [ config.sops.secrets.woff.path ];
      extraOptions = [ "--label=traefik.http.routers.woff.rule=Host(`pay.nichi.co`)" ];
    };
  };
  # TODO: tighten permission on control socket
  systemd.sockets.podman.socketConfig = {
    SocketMode = "0666";
    DirectoryMode = "0755";
  };
  virtualisation.containers.containersConf.settings.engine = {
    events_logger = "file";
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        https = {
          address = ":443";
          http.tls.certResolver = "le";
        };
      };
      certificatesResolvers.le.acme = {
        email = "blackhole@nichi.co";
        storage = config.services.traefik.dataDir + "/acme.json";
        keyType = "EC256";
        tlsChallenge = {};
      };
      providers.docker.endpoint = "unix:///run/podman/podman.sock";
      api = {
        dashboard = true;
      };
    };
    dynamicConfigOptions = {
      tls.options.default = {
        minVersion = "VersionTLS12";
        sniStrict = true;
        cipherSuites = [
          "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
          "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
          "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
        ];
      };
      http = {
        routers = {
          dashboard = {
            rule = "Host(`traefik.nichi.co`)";
            service = "api@internal";
          };
          rait = {
            rule = "Host(`api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait" ];
            service = "rait";
          };
        };
        middlewares.rait.replacePath = {
          path = "/gravity/combined.json";
        };
        services = {
          rait.loadBalancer = {
            passHostHeader = false;
            servers = [
              {
                url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com";
              }
            ];
          };
        };
      };
    };
  };
}
