{ pkgs, config, ... }:
let mkService = { ExecStart, EnvironmentFile }: {
  serviceConfig = {
    DynamicUser = true;
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateUsers = true;
    PrivateDevices = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectProc = "invisible";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    CapabilityBoundingSet = "";
    ProtectHostname = true;
    ProcSubset = "pid";
    SystemCallArchitectures = "native";
    UMask = "0077";
    SystemCallFilter = "@system-service";
    SystemCallErrorNumber = "EPERM";
    Restart = "always";
    inherit ExecStart EnvironmentFile;
  };
  wantedBy = [ "multi-user.target" ];
};
in
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
          S3_REGION = "us-east-1";
          S3_BUCKET = "pastebin";
          S3_ENDPOINT = "https://s3.nichi.co";
        };
        environmentFiles = [ config.sops.secrets.meow.path ];
        extraOptions = [
          "--label=traefik.http.routers.meow.rule=Host(`pb.nichi.co`)"
          "--label=traefik.http.services.meow.loadbalancer.server.port=8080"
        ];
      };
    woff =
      let image = pkgs.woff.image; in
      {
        image = "${image.imageName}:${image.imageTag}";
        imageFile = image;
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
  systemd.services.quark = mkService {
    ExecStart = "${pkgs.quark}/bin/quark -l 127.0.0.1:8000";
    EnvironmentFile = config.sops.secrets.quark.path;
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
  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
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
    };
    dynamicConfigOptions = {
      tls.options.default = {
        minVersion = "VersionTLS12";
        sniStrict = true;
      };
      http = {
        routers = {
          rait = {
            rule = "Host(`api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait0" "rait1" "rait2" ];
            service = "rait";
          };
          quark = {
            rule = "Host(`cache.nichi.co`)";
            service = "quark";
          };
        };
        middlewares = {
          rait0.replacePath = {
            path = "/tuna/gravity/artifacts/artifacts/combined.json";
          };
          rait1.basicAuth = {
            users = [ "{{ env `RAIT_PASSWD` }}" ];
            removeheader = true;
          };
          rait2.headers = {
            customrequestheaders.authorization = "token {{ env `GITHUB_TOKEN` }}";
          };
        };
        services = {
          quark.loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8000";
            }];
          };
          rait.loadBalancer = {
            passHostHeader = false;
            servers = [{
              url = "https://raw.githubusercontent.com";
            }];
          };
        };
      };
    };
  };
}
