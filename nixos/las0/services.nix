{ pkgs, config, ... }:
{
  fileSystems."/data" = {
    label = "minio";
    fsType = "ext4";
  };

  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = "127.0.0.1:8086";
    };
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
          influx = {
            rule = "Host(`stats.nichi.co`)";
            service = "influx";
          };
        };
        services = {
          influx.loadBalancer = {
            passHostHeader = true;
            servers = [{
              url = "http://${config.services.influxdb2.settings.http-bind-address}";
            }];
          };
        };
      };
    };
  };
}
