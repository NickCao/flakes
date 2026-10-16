{
  config,
  utils,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.metrics;
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };

    cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
      match = lib.singleton {
        host = lib.singleton config.networking.fqdn;
        path = lib.singleton "/metrics";
      };
      handle = lib.singleton {
        handler = "reverse_proxy";
        upstreams =
          with config.services.prometheus.exporters.node;
          lib.singleton { dial = "${listenAddress}:${toString port}"; };
      };
    };

    systemd.sockets.spiffe-systemd-journal-upload = {
      wantedBy = [ "sockets.target" ];
      requiredBy = [
        config.systemd.services.spiffe-systemd-journal-upload.name
        config.systemd.services.systemd-journal-upload.name
      ];
      before = [
        config.systemd.services.systemd-journal-upload.name
      ];
      listenStreams = [ "127.0.0.1:8000" ];
      socketConfig = {
        PrivateNetwork = true;
        FileDescriptorName = "spiffe-systemd-journal-upload";
      };
    };

    systemd.services.systemd-journal-upload = {
      unitConfig.JoinsNamespaceOf = config.systemd.sockets.spiffe-systemd-journal-upload.name;
      serviceConfig.PrivateNetwork = true;
    };

    # Restart the service when the socket changes
    systemd.services.spiffe-systemd-journal-upload.restartTriggers = [
      config.systemd.units.${config.systemd.sockets.spiffe-systemd-journal-upload.name}.unit
    ];

    cloud.services.spiffe-systemd-journal-upload.config = {
      ExecStart = utils.escapeSystemdExecArgs [
        (lib.getExe pkgs.ghostunnel)
        "client"
        "--use-workload-api-addr=unix:///run/spire/agent/public/api.sock"
        "--listen=systemd:spiffe-systemd-journal-upload"
        "--target=logs.nichi.co:9429"
        "--verify-uri=spiffe://nichi.link/victorialogs"
      ];
    };

    services.journald.upload = {
      enable = true;
      settings.Upload = {
        URL = "http://127.0.0.1:8000/insert/journald";
        NetworkTimeoutSec = "5m";
        Compression = "zstd:4";
        ForceCompression = true;
      };
    };
  };
}
