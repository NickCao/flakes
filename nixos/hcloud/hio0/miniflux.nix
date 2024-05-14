{ config, ... }:
let
  hostName = "rss.nichi.co";
  baseURL = "https://${hostName}";
in
{
  sops.secrets.miniflux = {
    restartUnits = [ "miniflux.service" ];
  };
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux.path;
    config = {
      LISTEN_ADDR = "127.0.0.1:9123";
      BASE_URL = baseURL;
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "${baseURL}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.nichi.co/realms/nichi";
      OAUTH2_USER_CREATION = 1;
    };
  };
  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ hostName ]; } ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = config.services.miniflux.config.LISTEN_ADDR; } ];
        }
      ];
    }
  ];
}
