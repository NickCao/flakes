{
  config,
  pkgs,
  lib,
  data,
  ...
}:
let
  hostName = "rss.nichi.co";
  baseURL = "https://${hostName}";
in
{
  sops.secrets.miniflux = {
    restartUnits = [ config.systemd.services.miniflux.name ];
  };

  # https://miniflux.app/docs/howto.html#systemd-socket-activation
  systemd.sockets.miniflux = {
    wantedBy = [ "sockets.target" ];
    requiredBy = [ config.systemd.services.miniflux.name ];
    listenStreams = [ "/run/miniflux.sock" ];
  };

  systemd.services.miniflux.serviceConfig.NonBlocking = true;

  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      BASE_URL = baseURL;
      CREATE_ADMIN = 0;
      DISABLE_LOCAL_AUTH = 1;

      TRUSTED_REVERSE_PROXY_NETWORKS = "127.0.0.1/32";
      AUTH_PROXY_HEADER = "X-Auth-Request-User";
      AUTH_PROXY_USER_CREATION = 0;
    };
  };

  cloud.caddy.mtls = lib.singleton hostName;
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton hostName; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      headers.request.set."X-Auth-Request-User" = lib.singleton "{http.request.tls.client.san.emails.0}";
      upstreams = lib.singleton { dial = "unix//run/miniflux.sock"; };
    };
  };
}
