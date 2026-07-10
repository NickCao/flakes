{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.stalwart = { };

  services.redis.servers.stalwart = {
    enable = true;
  };

  systemd.services.stalwart.serviceConfig.SupplementaryGroups = [
    config.services.redis.servers.stalwart.group
  ];

  services.stalwart = {
    enable = true;
    settings = {
      "@type" = "Sqlite";
      path = "/var/lib/stalwart/db.sqlite";
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
            path = "/var/lib/stalwart/blobs";
            depth = 2;
          };
        }
        {
          "@type" = "update";
          object = "InMemoryStore";
          value = {
            "@type" = "Redis";
            url = "redis+unix://${config.services.redis.servers.stalwart.unixSocket}";
          };
        }
        {
          "@type" = "upsert";
          object = "Tracer";
          matchOn = [ "@type" ];
          value = {
            tracer-stdout = {
              "@type" = "Stdout";
              enable = true;
              buffered = true;
              ansi = false;
              multiline = false;
              level = "info";
              lossy = false;
              events = { };
              eventsPolicy = "exclude";
            };
          };
        }
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
        {
          "@type" = "upsert";
          object = "DnsServer";
          matchOn = [ "description" ];
          value = {
            dnsserver-iad0 = {
              "@type" = "Tsig";
              description = "iad0.nichi.link";
              # FIXME: secrets
            };
          };
        }
        {
          "@type" = "upsert";
          matchOn = [ "name" ];
          object = "Domain";
          value = {
            domain-scp-link = {
              isEnabled = true;
              name = "scp.link";
              description = "scp.link";
              # FIXME: acme
              dnsManagement = {
                "@type" = "Automatic";
                origin = null;
                dnsServerId = "#dnsserver-iad0";
                publishRecords = {
                  autoConfig = true;
                  autoConfigLegacy = false;
                  autoDiscover = false;
                  caa = false; # prevents caddy from renewing cert
                  dkim = true;
                  dmarc = true;
                  mtaSts = true;
                  mx = true;
                  spf = true;
                  srv = true;
                  tlsRpt = true;
                };
              };
            };
          };
        }
        {
          "@type" = "update";
          object = "SystemSettings";
          value = {
            defaultHostname = "hel1.nichi.link";
            defaultDomainId = "#domain-scp-link";
            defaultCertificateId = null;

            threadPoolSize = null;
            maxConnections = 8192;
            proxyTrustedNetworks = {
              "127.0.0.1" = true;
            };

            mailExchangers = {
              "0" = {
                hostname = null;
                priority = 10;
              };
            };

            providerInfo = { };

            services = {
              smtp = {
                hostname = "mail.scp.link";
                cleartext = false;
              };
              imap = {
                hostname = "mail.scp.link";
                cleartext = false;
              };
              jmap = {
                hostname = "mail.scp.link";
                cleartext = false;
              };
              caldav = {
                hostname = "mail.scp.link";
                cleartext = false;
              };
              carddav = {
                hostname = "mail.scp.link";
                cleartext = false;
              };
              webdav = {
                hostname = "mail.scp.link";
                cleartext = false;
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
