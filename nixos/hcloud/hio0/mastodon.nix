{ config, pkgs, lib, ... }: {

  services.mastodon = {
    enable = true;
    localDomain = "nichi.co";
    smtp = {
      createLocally = false;
      fromAddress = "mastodon@nichi.co";
    };
    extraConfig = {
      WEB_DOMAIN = "mastodon.nichi.co";
      OIDC_ENABLED = "true";
      OIDC_DISPLAY_NAME = "id.nichi.co";
      OIDC_CLIENT_AUTH_METHOD = "query";
      OIDC_ISSUER = "https://id.nichi.co";
      OIDC_UID_FIELD = "preferred_username";
      OIDC_SEND_SCOPE_TO_TOKEN_ENDPOINT = "false";
      OIDC_DISCOVERY = "true";
      OIDC_SCOPE = "openid,profile,email";
      OIDC_CLIENT_ID = "mastodon";
      OIDC_CLIENT_SECRET = "insecure_secret";
      OIDC_REDIRECT_URI = "https://mastodon.nichi.co/auth/auth/openid_connect/callback";
      OIDC_SECURITY_ASSUME_EMAIL_IS_VERIFIED = "true";
    };
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [ "mastodon" ];

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [{
        host = [ "mastodon.nichi.co" ];
        path = [ "/system/*" ];
      }];
      handle = [
        {
          "handler" = "rewrite";
          "strip_path_prefix" = "/system";
        }
        {
          handler = "file_server";
          root = "/var/lib/mastodon/public-system";
        }
      ];
    }
    {
      match = [{
        host = [ "mastodon.nichi.co" ];
        path = [ "/api/v1/streaming/*" ];
      }];
      handle = [{
        handler = "reverse_proxy";
        upstreams = [{ dial = "unix//run/mastodon-streaming/streaming.socket"; }];
      }];
    }
    {
      match = [{
        host = [ "mastodon.nichi.co" ];
      }];
      handle = [
        {
          handler = "file_server";
          root = "${pkgs.mastodon}/public";
          pass_thru = true;
        }
        {
          handler = "reverse_proxy";
          upstreams = [{ dial = "unix//run/mastodon-web/web.socket"; }];
        }
      ];
    }
  ];


}
