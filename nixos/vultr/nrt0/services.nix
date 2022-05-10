{ pkgs, config, ... }:
{
  cloud.services.woff.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --no-check ${../../../fn/woff.ts}";
    EnvironmentFile = config.sops.secrets.woff.path;
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8001" "DENO_DIR=/tmp" ];
  };

  cloud.services.blog.config = {
    ExecStart = "${pkgs.serve}/bin/serve -l 127.0.0.1:8003 -p ${pkgs.nichi}";
  };

  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
  services.traefik = {
    dynamicConfigOptions = {
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
            accessControlAllowMethods = [ "GET" ];
            accessControlAllowOriginList = [ "https://matrix.nichi.co" ];
            accessControlMaxAge = 3600;
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
