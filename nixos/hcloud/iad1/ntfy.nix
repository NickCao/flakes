{ config, ... }:
{

  services.ntfy-sh = {
    enable = false; # FIXME
    settings = {
      base-url = "https://ntfy.nichi.co";
      listen-http = "";
      listen-unix = "/run/ntfy-sh/ntfy.sock";
      listen-unix-mode = 511; # 0777
      behind-proxy = true;
    };
  };

  systemd.services.ntfy-sh.serviceConfig.RuntimeDirectory = [ "ntfy-sh" ];

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ "ntfy.nichi.co" ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "unix/${config.services.ntfy-sh.settings.listen-unix}"; } ];
        }
      ];
    }
  ];
}
