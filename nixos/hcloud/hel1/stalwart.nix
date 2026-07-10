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
          matchOn = [ "description" ];
          object = "Directory";
          value = {
            directory-iz07tzgaaaqa = {
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
