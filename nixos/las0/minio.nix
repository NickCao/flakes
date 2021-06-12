{ pkgs, config, ... }:
{
  fileSystems."/data" = {
    label = "minio";
    fsType = "ext4";
  };

  services.minio = {
    enable = true;
    browser = true;
    listenAddress = "127.0.0.1:9000";
    configDir = "/data/minio/config";
    dataDir = builtins.map (x: "/data/minio/ec" + builtins.toString x) [ 0 1 2 3 ];
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
          n8n = {
            rule = "Host(`n8n.nichi.co`)";
            service = "n8n";
          };
        };
        services = {
          minio.loadBalancer = {
            passHostHeader = true;
            servers = [{
              url = "http://${config.services.minio.listenAddress}";
            }];
          };
          n8n.loadBalancer = {
            passHostHeader = true;
            servers = [{
              url = "http://127.0.0.1:8080";
            }];
          };
        };
      };
    };
  };
}
