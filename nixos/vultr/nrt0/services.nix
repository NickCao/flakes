{ pkgs, config, ... }:
{
  cloud.services.woff = {
    exec = "${pkgs.woff}/bin/woff -l 127.0.0.1:8001";
    envFile = config.sops.secrets.woff.path;
  };

  cloud.services.blog = {
    exec = "${pkgs.serve}/bin/serve -l 127.0.0.1:8003 -p ${pkgs.nichi}";
  };

  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
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
      };
      http = {
        routers = {
          rait = {
            rule = "Host(`api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait0" "rait1" "rait2" ];
            service = "rait";
          };
          woff = {
            rule = "Host(`pay.nichi.co`)";
            service = "woff";
          };
          blog = {
            rule = "Host(`nichi.co`)";
            middlewares = [ "blog" ];
            service = "blog";
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
          blog.headers = {
            stsSeconds = 31536000;
            stsIncludeSubdomains = true;
            stsPreload = true;
          };
        };
        services = {
          woff.loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8001";
            }];
          };
          blog.loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8003";
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
