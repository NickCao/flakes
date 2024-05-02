{ pkgs, config, ... }:
{

  cloud.services.meow.config = {
    ExecStart = "${pkgs.meow}/bin/meow --listen 127.0.0.1:8002 --base-url https://pb.nichi.co --data-dir \${STATE_DIRECTORY}";
    StateDirectory = "meow";
    SystemCallFilter = null;
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "pb.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:8002"; } ];
        }
      ];
    }
  ];
}
