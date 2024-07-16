{
  pkgs,
  config,
  lib,
  ...
}:
{
  cloud.services.meow.config = {
    ExecStart = lib.escapeShellArgs [
      "${pkgs.meow}/bin/meow"
      "--listen"
      "127.0.0.1:${toString config.lib.ports.meow}"
      "--base-url"
      "https://pb.nichi.co"
      "--data-dir"
      "\${STATE_DIRECTORY}"
    ];
    StateDirectory = "meow";
    SystemCallFilter = null;
  };

  systemd.tmpfiles.settings = {
    "10-meow" = {
      "/var/lib/meow".e.age = "30d";
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "pb.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.meow}"; } ];
        }
      ];
    }
  ];
}
