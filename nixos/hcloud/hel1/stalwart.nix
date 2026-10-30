{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) fqdn;
  base = "scp.link";
  host = "mail.${base}";
in
{
  sops.secrets.stalwart = { };

  systemd.services.stalwart.environment = {
    STALWART_PUBLIC_URL = "https://${host}";
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
          object = "Tracer";
          matchOn = [ "@type" ];
          value = {
            tracer-journal = {
              "@type" = "Stdout";
              enable = true;
              ansi = false;
              multiline = false;
              level = "info";
              lossy = false;
              eventsPolicy = "exclude";
              events = { };
            };
          };
        }
        {
          "@type" = "update";
          object = "SystemSettings";
          value = {
            defaultHostname = fqdn;
            mailExchangers = {
              "0" = {
                hostname = fqdn;
                priority = 10;
              };
            };
            services = {
              imap = { };
              smtp = { };
              jmap = {
                hostname = host;
              };
              caldav = {
                hostname = host;
              };
              carddav = {
                hostname = host;
              };
              webdav = {
                hostname = host;
              };
            };
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
        {
          "@type" = "reconcile";
          object = "Directory";
          matchOn = [ "description" ];
          value = {
            directory-keycloack = {
              "@type" = "Oidc";
              description = "keycloak";
              issuerUrl = "https://id.nichi.co/realms/nichi";
              usernameDomain = base;

              claimUsername = "preferred_username";
              claimName = "name";
              claimGroups = null;

              allowIdTokenClaims = false;
              allowInvalidCerts = false;
              skipAudienceValidation = false;
              lenientIssuerMatch = false;
              unscopedTokens = "reject";
              opaqueTokenValidation = "none";
              acceptedAudiences = { };

              introspectionAuthMethod = "clientSecretBasic";
              introspectionClientId = null;
              introspectionClientSecret = {
                "@type" = "None";
              };
            };
          };
        }
        {
          "@type" = "reconcile";
          object = "Certificate";
          matchOn = [ "subjectAlternativeNames" ];
          value = {
            certificate-default = {
              subjectAlternativeNames = {
                "${fqdn}" = true;
              };
              certificate = {
                "@type" = "File";
                filePath = "/run/credentials/stalwart.service/${fqdn}.crt";
              };
              privateKey = {
                "@type" = "File";
                filePath = "/run/credentials/stalwart.service/${fqdn}.key";
              };
            };
          };
        }
        {
          "@type" = "reconcile";
          object = "Domain";
          matchOn = [
            "name"
          ];
          value = {
            domain-default = {
              enable = true;
              name = base;
              aliases = { };
              description = null;
              catchAllAddress = null;
              allowRelaying = false;
              reportAddressUri = "mailto:postmaster";

              subAddressing = {
                "@type" = "Enabled";
              };

              dnsManagement = {
                "@type" = "Automatic";
                dnsServerId = "jl7benlyaaaa"; # FIXME
                origin = null;
                publishRecords = {
                  dkim = true;
                  tlsa = true;
                  spf = true;
                  mx = true;
                  dmarc = true;
                  mtaSts = true;
                  tlsRpt = true;
                  autoConfig = true;
                };
              };
              certificateManagement = {
                "@type" = "Manual";
              };
              dkimManagement = {
                "@type" = "Automatic";
              };
            };
          };
        }
      ];
    };
  };

  cloud.caddy.settings.apps.tls.certificates = {
    automate = lib.singleton fqdn;
  };

  # TODO: periodically reload certificate
  systemd.services.stalwart.serviceConfig = {
    RefreshOnReload = [ "credentials" ];
    LoadCredential =
      let
        src = "/var/lib/caddy/certificates/acme-v02.api.letsencrypt.org-directory";
      in
      [
        "${fqdn}.crt:${src}/${fqdn}/${fqdn}.crt"
        "${fqdn}.key:${src}/${fqdn}/${fqdn}.key"
      ];
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = lib.singleton {
        host = [ host ];
        path = [ "/oauth-clients/thunderbird.json" ];
      };
      handle = lib.singleton {
        handler = "static_response";
        status_code = 200;
        headers = {
          Content-Type = [ "application/json" ];
        };
        body = builtins.toJSON {
          client_id = "https://${host}/oauth-clients/thunderbird.json";
          client_name = "Thunderbird";
          redirect_uris = [
            "http://localhost"
          ];
          grant_types = [
            "authorization_code"
            "refresh_token"
          ];
          response_types = [
            "code"
          ];
          application_type = "native";
          token_endpoint_auth_method = "none";
        };
      };
    }
    {
      match = lib.singleton {
        host = [
          host
          "mta-sts.${base}"
          "ua-auto-config.${base}"
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
    }
  ];
}
