{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.stalwart = { };

  systemd.services.stalwart.environment = {
    STALWART_PUBLIC_URL = "https://mail.scp.link";
  };

  services.stalwart = {
    enable = true;
    settings = {
      "@type" = "Sqlite";
      path = "/var/lib/stalwart/data.sqlite";
    };
    apply = {
      enable = true;
      credentialFile = config.sops.secrets.stalwart.path;
      plan = [
        {
          "@type" = "update";
          object = "BlobStore";
          value = {
            "@type" = "FileSystem";
            path = "/var/lib/stalwart/blob/";
            depth = 2;
          };
        }
        {
          "@type" = "update";
          object = "InMemoryStore";
          value = {
            "@type" = "Default";
          };
        }
        {
          "@type" = "update";
          object = "SearchStore";
          value = {
            "@type" = "Default";
          };
        }
        {
          "@type" = "reconcile";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            networklistener-http = {
              name = "http";
              protocol = "http";
              bind = {
                "127.0.0.1:8080" = true;
              };
              overrideProxyTrustedNetworks = {
                "127.0.0.1" = true;
              };
              useTls = false;
              implicitTls = false;
            };
            networklistener-imaps = {
              name = "imaps";
              protocol = "imap";
              bind = {
                "[::]:993" = true;
              };
              overrideProxyTrustedNetworks = { };
              useTls = true;
              implicitTls = true;
            };
            networklistener-submissions = {
              name = "submissions";
              protocol = "smtp";
              bind = {
                "[::]:465" = true;
              };
              overrideProxyTrustedNetworks = { };
              useTls = true;
              implicitTls = true;
            };
            networklistener-smtp = {
              name = "smtp";
              protocol = "smtp";
              bind = {
                "[::]:25" = true;
              };
              overrideProxyTrustedNetworks = { };
              useTls = true;
              implicitTls = false;
            };
          };
        }
        {
          "@type" = "update";
          object = "SpamSettings";
          value = {
            spamFilterRulesUrl = "file://${pkgs.stalwart_1_0.spam-filter}/spam-filter-rules.json.gz";
          };
        }
        {
          "@type" = "reconcile";
          object = "Application";
          matchOn = [
            "description"
          ];
          value = {
            application-webui = {
              enable = true;
              description = "Stalwart Web Interface";
              resourceUrl = "file://${pkgs.stalwart_1_0.webui}/webui.zip";
              oauthClientId = null;
              unpackDirectory = null;
              autoUpdateInterval = 7776000000;
              urlPrefix = {
                "/admin" = true;
                "/account" = true;
              };
            };
          };
        }
      ];
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton {
      host = [
        "mail.scp.link"
        "mta-sts.scp.link"
        "ua-auto-config.scp.link"
      ];
    };
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
