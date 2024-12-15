{
  config,
  pkgs,
  lib,
  ...
}:
{

  sops.secrets = {
    mastodon = {
      restartUnits = [
        config.systemd.services.mastodon-web.name
        config.systemd.services.mastodon-sidekiq-all.name
      ];
    };
    mastodon-readonly = {
      restartUnits = [ config.systemd.services.oproxy.name ];
    };
  };

  systemd.services.mastodon-web.serviceConfig.EnvironmentFile = [
    config.sops.secrets.mastodon.path
  ];

  systemd.services.mastodon-sidekiq-all.serviceConfig.EnvironmentFile = [
    config.sops.secrets.mastodon.path
  ];

  services.mastodon = {
    enable = true;
    localDomain = "nichi.co";
    mediaAutoRemove = {
      enable = true;
      olderThanDays = 14;
    };
    streamingProcesses = 3;
    smtp = {
      createLocally = false;
      fromAddress = "mastodon@nichi.co";
    };
    extraConfig = rec {
      WEB_DOMAIN = "mastodon.nichi.co";

      OMNIAUTH_ONLY = "true";

      S3_ENABLED = "true";
      S3_ENDPOINT = "https://s3.us-east-005.backblazeb2.com";
      S3_BUCKET = "nichi-mastodon";
      S3_ALIAS_HOST = "${WEB_DOMAIN}/system";
      S3_RETRY_LIMIT = "5";
      S3_PERMISSION = "";

      OIDC_ENABLED = "true";
      OIDC_DISPLAY_NAME = "id.nichi.co";
      OIDC_ISSUER = "https://id.nichi.co/realms/nichi";
      OIDC_DISCOVERY = "true";
      OIDC_SCOPE = "openid,profile,email";
      OIDC_UID_FIELD = "preferred_username";
      OIDC_REDIRECT_URI = "https://${WEB_DOMAIN}/auth/auth/openid_connect/callback";
      OIDC_SECURITY_ASSUME_EMAIL_IS_VERIFIED = "true";

      OIDC_CLIENT_ID = "mastodon";
    };
  };

  cloud.services.oproxy.config = {
    ExecStart = lib.escapeShellArgs [
      "${pkgs.oproxy}/bin/oproxy"
      "--s3-endpoint"
      config.services.mastodon.extraConfig.S3_ENDPOINT
      "--s3-bucket"
      config.services.mastodon.extraConfig.S3_BUCKET
      "--listen"
      "127.0.0.1:${toString config.lib.ports.oproxy}"
    ];
    EnvironmentFile = [
      config.sops.secrets.mastodon-readonly.path
    ];
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [ "mastodon" ];

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [ { host = [ config.services.mastodon.extraConfig.WEB_DOMAIN ]; } ];
      handle = [
        {
          handler = "subroute";
          routes = [
            {
              match = [ { path = [ "/system/*" ]; } ];
              handle = [
                {
                  handler = "rewrite";
                  strip_path_prefix = "/system";
                }
                {
                  handler = "reverse_proxy";
                  upstreams = [
                    { dial = "127.0.0.1:${toString config.lib.ports.oproxy}"; }
                  ];
                }
              ];
            }
            {
              match = [ { path = [ "/api/v1/streaming/*" ]; } ];
              handle = [
                {
                  handler = "reverse_proxy";
                  upstreams = lib.genList (i: {
                    dial = "unix//run/mastodon-streaming/streaming-${toString (i + 1)}.socket";
                  }) config.services.mastodon.streamingProcesses;
                }
              ];
            }
            {
              handle = [
                {
                  handler = "file_server";
                  root = "${pkgs.mastodon}/public";
                  pass_thru = true;
                }
                {
                  handler = "reverse_proxy";
                  upstreams = [ { dial = "unix//run/mastodon-web/web.socket"; } ];
                }
              ];
            }
          ];
        }
      ];
    }
  ];
}
