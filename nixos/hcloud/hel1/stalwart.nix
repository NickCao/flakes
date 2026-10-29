{
  config,
  lib,
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
