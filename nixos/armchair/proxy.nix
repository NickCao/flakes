{
  lib,
  pkgs,
  ca,
  ...
}:
{
  cloud.caddy.settings.apps.http.servers.default.tls_connection_policies = lib.singleton {
    match = {
      sni = lib.singleton "immich.nichi.co";
    };
    client_authentication = {
      mode = "require_and_verify";
      ca = {
        provider = "file";
        pem_files = lib.singleton (pkgs.writeText "root.pem" ca);
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "immich.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton { dial = "subframe.lan:2283"; };
    };
  };
}
