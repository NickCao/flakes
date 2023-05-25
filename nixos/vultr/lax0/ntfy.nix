{ config, ... }: {

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nichi.co";
      listen-http = "";
      listen-unix = "/var/lib/ntfy-sh/ntfy.sock";
      listen-unix-mode = 511; # 0777
      behind-proxy = true;
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ "ntfy.nichi.co" ];
    }];
    handle = [{
      handler = "reverse_proxy";
      upstreams = [{ dial = "unix/${config.services.ntfy-sh.settings.listen-unix}"; }];
    }];
  }];

}
