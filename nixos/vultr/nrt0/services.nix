{ pkgs, config, ... }:
{
  cloud.services.fn.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --no-check ${../../../fn}/index.ts";
    EnvironmentFile = config.sops.secrets.woff.path;
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8001" "DENO_DIR=/tmp" ];
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
          fn = {
            rule = "Host(`fn.nichi.co`)";
            service = "fn";
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
          fn.loadBalancer = {
            servers = [{
              url = "http://127.0.0.1:8001";
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
