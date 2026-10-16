{
  config,
  pkgs,
  lib,
  utils,
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
        { address = "192.168.1.183"; }
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

  cloud.services.spiffe-prometheus-nut-exporter.config = {
    ExecStart =
      with config.services.prometheus.exporters.nut;
      utils.escapeSystemdExecArgs [
        (lib.getExe pkgs.ghostunnel)
        "server"
        "--use-workload-api-addr=unix:///run/spire/agent/public/api.sock"
        "--listen=[::]:9318"
        "--target=${listenAddress}:${toString port}"
        "--allow-uri=spiffe://nichi.link/victoriametrics"
      ];
  };
}
