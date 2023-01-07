{ pkgs, config, ... }:
{
  cloud.services.fn.config = {
    ExecStart = "${pkgs.python3.withPackages (ps: with ps; [ uvicorn fastapi ])}/bin/python ${../../../fn/index.py}";
    Environment = [ "PORT=8001" ];
  };

  cloud.services.rants.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --no-check ${../../../fn/rants.ts}";
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8002" "DENO_DIR=/tmp" ];
  };

  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          rait = {
            rule = "Host(`api.nichi.co`, `fn.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait" ];
            service = "fn";
          };
          fn = {
            rule = "Host(`fn.nichi.co`)";
            service = "fn";
          };
          rants = {
            rule = "Host(`fn.nichi.co`) && PathPrefix(`/rants`)";
            middlewares = [ "rants" ];
            service = "rants";
          };
        };
        middlewares = {
          rait.basicAuth = {
            users = [ "{{ env `RAIT_PASSWD` }}" ];
            removeheader = true;
          };
          rants.stripPrefix.prefixes = [ "/rants" ];
        };
        services = {
          rants.loadBalancer.servers = [{ url = "http://127.0.0.1:8002"; }];
          fn.loadBalancer.servers = [{ url = "http://127.0.0.1:8001"; }];
        };
      };
    };
  };
}
