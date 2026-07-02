{
  config,
  lib,
  data,
  ...
}:
let
  cfg = config.services.acme-dns.settings;
in
{
  services.acme-dns = {
    enable = true;
    settings = {
      general = {
        listen = "[::]:53";
        protocol = "both";

        domain = "acme-dns.nichi.co";
        nsname = "hel1.nichi.link";
        nsadmin = "noc.nichi.link";

        records = [
          "${cfg.general.domain}. NS   ${cfg.general.nsname}."
          "${cfg.general.domain}. A    ${data.nodes.hel1.ipv4}"
          "${cfg.general.domain}. AAAA ${data.nodes.hel1.ipv6}"
        ];
      };
      api = {
        ip = "127.0.0.1";
        disable_registration = true;
        port = 9237;
        tls = "none";
        use_header = true;
        header_name = "X-Forwarded-For";
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton cfg.general.domain; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = "${cfg.api.ip}:${toString cfg.api.port}";
      };
    };
  };
}
