{
  config,
  pkgs,
  ...
}:
{
  power.ups = {
    enable = true;
    mode = "none";
    upsd = {
      enable = true;
      listen = [
        { address = "::1"; }
        { address = "127.0.0.1"; }
        { address = "192.168.1.210"; }
      ];
    };
    ups.cp1500 = {
      driver = "usbhid-ups";
      port = "auto";
    };
    users.secondary = {
      passwordFile = toString (pkgs.writeText "password" "secondary");
      upsmon = "secondary";
    };
  };

  systemd.services.upsd.after = [ "network-online.target" ];
  systemd.services.upsd.wants = [ "network-online.target" ];

  services.prometheus.exporters.nut = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  cloud.ghostunnel.servers.spiffe-prometheus-nut-exporter = {
    listen = "[::]:9318";
    target = with config.services.prometheus.exporters.nut; "${listenAddress}:${toString port}";
    allowURIs = [ "spiffe://nichi.link/victoriametrics" ];
  };
}
