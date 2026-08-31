{ config, lib, ... }:
{
  power.ups = {
    enable = true;
    mode = "none";
    upsd = {
      enable = true;
      listen = lib.singleton { address = "*"; };
    };
    ups.cp1500 = {
      driver = "usbhid-ups";
      port = "auto";
    };
  };

  services.prometheus.exporters.nut = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [
        {
          host = [ config.networking.fqdn ];
          path = [ "/ups_metrics" ];
        }
      ];
      handle = [
        {
          handler = "authentication";
          providers.http_basic = {
            accounts = [
              {
                username = "prometheus";
                password = "{env.PROM_PASSWD}";
              }
            ];
            hash_cache = { };
          };
        }
        {
          handler = "reverse_proxy";
          upstreams = with config.services.prometheus.exporters.nut; [
            { dial = "${listenAddress}:${toString port}"; }
          ];
        }
      ];
    }
  ];
}
