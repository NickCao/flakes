{ config, ... }:
let
  hostName = "rss.nichi.co";
  baseURL = "https://${hostName}";
in
{
  sops.secrets.miniflux = {
    restartUnits = [ "miniflux.service" ];
  };
  systemd.sockets.miniflux = {
    wantedBy = [ "sockets.target" ];
    requiredBy = [ "miniflux.service" ];
    listenStreams = [ "/run/miniflux.sock" ];
  };
  systemd.services.miniflux.serviceConfig.NonBlocking = true;
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      BASE_URL = baseURL;
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "${baseURL}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.nichi.co/realms/nichi";
      OAUTH2_USER_CREATION = 1;
      POLLING_FREQUENCY = 30;
      SCHEDULER_ROUND_ROBIN_MIN_INTERVAL = 30;
    };
  };
  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ hostName ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "unix//run/miniflux.sock"; } ];
        }
      ];
    }
  ];
}
