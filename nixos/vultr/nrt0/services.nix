{ pkgs, config, ... }: {

  cloud.services.fn.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --allow-read --no-check ${../../../fn}/index.ts";
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8002" "DENO_DIR=/tmp" ];
  };

  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          rait = {
            rule = "Host(`fn.nichi.co`, `api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait" ];
            service = "fn";
          };
          fn = {
            rule = "Host(`fn.nichi.co`)";
            service = "fn";
          };
        };
        middlewares = {
          rait.basicAuth = {
            users = [ "{{ env `RAIT_PASSWD` }}" ];
            removeheader = true;
          };
        };
        services = {
          fn.loadBalancer.servers = [{ url = "http://127.0.0.1:8002"; }];
        };
      };
    };
  };

}
