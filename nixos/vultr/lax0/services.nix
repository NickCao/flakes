{ pkgs, config, ... }: {

  sops.secrets.caddy = { };

  cloud.services.fn.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --allow-read --no-check ${../../../fn}/index.ts";
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8002" "DENO_DIR=/tmp" ];
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [ config.sops.secrets.caddy.path ];

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [{
        host = [ "fn.nichi.co" "api.nichi.co" ];
        path = [ "/rait" ];
      }];
      handle = [
        {
          handler = "authentication";
          providers.http_basic.accounts = [{
            username = "rait";
            password = "{env.RAIT_PASSWD}";
          }];
        }
        {
          handler = "reverse_proxy";
          upstreams = [{ dial = "127.0.0.1:8002"; }];
        }
      ];
    }
    {
      match = [{
        host = [ "fn.nichi.co" ];
      }];
      handle = [{
        handler = "reverse_proxy";
        upstreams = [{ dial = "127.0.0.1:8002"; }];
      }];
    }
  ];

}
