{
  lib,
  ...
}:
{
  cloud.caddy.mtls = lib.singleton "immich.nichi.co";
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "immich.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton { dial = "subframe.lan:2283"; };
    };
  };
}
