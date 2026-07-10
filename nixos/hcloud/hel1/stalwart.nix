{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.stalwart = { };

  services.stalwart = {
    enable = true;
    # credentialFile = pkgs.writeText "stalwart-creds" ''
    #   STALWART_RECOVERY_ADMIN=admin:f44278e8bad73a35384c726d0416ee37
    # '';
    apply = {
      enable = true;
      credentialFile = config.sops.secrets.stalwart.path;
      plan = [
        {
          "@type" = "upsert";
          object = "Directory";
          matchOn = [ "description" ];
          value = {
            directory-keycloak = {
              "@type" = "Oidc";
              description = "keycloak";
              memberTenantId = null;
              claimUsername = "preferred_username";
              claimName = null;
              claimGroups = null;
              issuerUrl = "https://id.nichi.co/realms/nichi";
              usernameDomain = "scp.link";
              requireAudience = "stalwart";
              requireScopes = {
                email = true;
                openid = true;
                profile = true;
                stalwart = true;
              };
            };
          };
        }
        {
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#directory-keycloak";
          };
        }
        {
          "@type" = "destroy";
          object = "NetworkListener";
          value = {
            name = "https";
          };
        }
        {
          "@type" = "destroy";
          object = "NetworkListener";
          value = {
            name = "pop3s";
          };
        }
        {
          "@type" = "destroy";
          object = "NetworkListener";
          value = {
            name = "sieve";
          };
        }
        {
          "@type" = "upsert";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            networklistener-http = {
              name = "http";
              protocol = "http";
              bind = {
                "127.0.0.1:8080" = true;
              };
              useTls = false;
              overrideProxyTrustedNetworks = {
                "127.0.0.1" = true;
              };
            };
            networklistener-smtp = {
              name = "smtp";
              protocol = "smtp";
              bind = {
                "[::]:25" = true;
              };
              useTls = true;
              tlsImplicit = false;
            };
            networklistener-submissions = {
              name = "submissions";
              protocol = "smtp";
              bind = {
                "[::]:465" = true;
              };
              useTls = true;
              tlsImplicit = true;
            };
            networklistener-imaps = {
              name = "imaps";
              protocol = "imap";
              bind = {
                "[::]:993" = true;
              };
              useTls = true;
              tlsImplicit = true;
            };
          };
        }
      ];
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "mail.scp.link"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      transport = {
        protocol = "http";
        proxy_protocol = "v2";
      };
      upstreams = lib.singleton { dial = "127.0.0.1:8080"; };
    };
  };
}
