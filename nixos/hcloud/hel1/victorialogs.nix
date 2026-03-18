{ config, lib, ... }:
{
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton {
      host = lib.singleton "logs.nichi.co";
    };
    handle = [
      {
        handler = "authentication";
        providers.http_basic = {
          accounts = lib.singleton {
            username = "vlagent";
            password = "{env.VL_PASSWORD}";
          };
          hash_cache = { };
        };
      }
      {
        handler = "reverse_proxy";
        upstreams = lib.singleton {
          dial = "${config.services.victorialogs.listenAddress}";
        };
      }
    ];
  };
}
