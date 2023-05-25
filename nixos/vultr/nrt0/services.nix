{ pkgs, config, ... }: {

  cloud.services.fn.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --allow-read --no-check ${../../../fn}/index.ts";
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8002" "DENO_DIR=/tmp" ];
  };


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
            password = "$2a$14$MZ3rVQAvrZTWuowGB5EnjefZi0qHzDKd3D6psDSbrOtro0pAtlHnS";
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
