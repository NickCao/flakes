{ lib, ... }: {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    settings = { };
    environment = { };
  };

  cloud.caddy.mtls = [
    "immich.nichi.co"
    "ha.nichi.co"
  ];

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = lib.singleton { host = lib.singleton "immich.nichi.co"; };
      handle = lib.singleton {
        handler = "reverse_proxy";
        upstreams = lib.singleton { dial = "127.0.0.1:2283"; };
      };
    }
    {
      match = lib.singleton { host = lib.singleton "ha.nichi.co"; };
      handle = lib.singleton {
        handler = "reverse_proxy";
        upstreams = lib.singleton { dial = "tcp4/homeassistant.lan:80"; };
      };
    }
  ];
}
