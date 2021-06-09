{ pkgs, config, ... }:
{
  fileSystems."/var/lib/minio" = {
    label = "minio";
    fsType = "ext4";
  };

  services.minio = {
    enable = true;
    browser = true;
    listenAddress = "127.0.0.1:9000";
    dataDir = builtins.map (x: "/var/lib/minio/data/ec" + builtins.toString x) [ 0 1 2 3 ];
  };
  systemd.services.minio.serviceConfig.EnvironmentFile = config.sops.secrets.minio.path;

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
        tlsChallenge = { };
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
          minio = {
            rule = "Host(`s3.nichi.co`)";
            service = "minio";
          };
        };
        services = {
          minio.loadBalancer = {
            passHostHeader = true;
            servers = [{
              url = "http://${config.services.minio.listenAddress}";
            }];
          };
        };
      };
    };
  };
}
