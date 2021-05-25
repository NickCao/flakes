{ pkgs, config, ... }:
{
  # TODO: force podman to use nftables
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    blog = let image = pkgs.nichi.image; in
      {
        image = "${image.imageName}:${image.imageTag}";
        imageFile = image;
        extraOptions = [
          "--label=traefik.http.routers.blog.rule=Host(`nichi.co`)"
          "--label=traefik.http.routers.blog.middlewares=blog"
          "--label=traefik.http.services.blog.loadbalancer.server.port=8080"
          "--label=traefik.http.middlewares.blog.headers.stsSeconds=31536000"
          "--label=traefik.http.middlewares.blog.headers.stsIncludeSubdomains=true"
          "--label=traefik.http.middlewares.blog.headers.stsPreload=true"
        ];
      };
    meow = let image = pkgs.meow.image; in
      {
        image = "${image.imageName}:${image.imageTag}";
        imageFile = image;
        environment = {
          BASE_URL = "https://pb.nichi.co";
          S3_BUCKET = "pastebin-nichi";
          S3_ENDPOINT = "https://s3.us-west-000.backblazeb2.com";
        };
        environmentFiles = [ config.sops.secrets.meow.path ];
        extraOptions = [
          "--label=traefik.http.routers.meow.rule=Host(`pb.nichi.co`)"
          "--label=traefik.http.services.meow.loadbalancer.server.port=8080"
        ];
      };
    woff = {
      image = "registry.gitlab.com/nickcao/functions/woff";
      environment = {
        RETURN_URL = "https://nichi.co";
      };
      environmentFiles = [ config.sops.secrets.woff.path ];
      extraOptions = [
        "--label=traefik.http.routers.woff.rule=Host(`pay.nichi.co`)"
        "--label=traefik.http.services.woff.loadbalancer.server.port=8080"
      ];
    };
  };
  systemd.services.podman-traefik = {
    serviceConfig = {
      Restart = "always";
      ExecStart = with config.services.traefik;"${pkgs.socat}/bin/socat UNIX-LISTEN:${dataDir}/podman.sock,group=${group},mode=0060,fork UNIX-CONNECT:/run/podman/podman.sock";
    };
    requires = [ "podman.socket" ];
    after = [ "podman.socket" ];
    wantedBy = [ "multi-user.target" ];
  };
  virtualisation.containers.containersConf.settings.engine = {
    events_logger = "file";
  };
  services.traefik = {
    enable = true;
    staticConfigOptions = {
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
        };
      };
      certificatesResolvers.le.acme = {
        email = "blackhole@nichi.co";
        storage = config.services.traefik.dataDir + "/acme.json";
        keyType = "EC256";
        tlsChallenge = { };
      };
      providers.docker = {
        endpoint = "unix://${config.services.traefik.dataDir}/podman.sock";
      };
      api = {
        dashboard = true;
      };
      pilot = {
        dashboard = false;
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
