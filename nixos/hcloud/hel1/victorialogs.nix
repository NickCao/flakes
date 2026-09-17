{ config, lib, ... }:
{
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
  };

  cloud.caddy.mtls = lib.singleton "logs.nichi.co";
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton {
      host = lib.singleton "logs.nichi.co";
    };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "${config.services.victorialogs.listenAddress}";
      };
    };
  };
}
