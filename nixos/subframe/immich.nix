{ lib, ... }: {
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    port = 2283;
    settings = { };
    environment = { };
  };

  cloud.caddy.mtls = [ "immich.nichi.co" ];
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "immich.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton { dial = "127.0.0.1:2283"; };
    };
  };
}
