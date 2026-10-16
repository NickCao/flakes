{
  config,
  lib,
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
      extraFlags = [ "--web.systemd-socket" ];
    };

    systemd.sockets.prometheus-node-exporter = {
      wantedBy = [ "sockets.target" ];
      requiredBy = [
        config.systemd.services.prometheus-node-exporter.name
        config.systemd.services.spiffe-prometheus-node-exporter.name
      ];
      before = [
        config.systemd.services.spiffe-prometheus-node-exporter.name
      ];
      listenStreams = [ "/run/prometheus-node-exporter.sock" ];
      socketConfig = {
        SocketGroup = config.services.prometheus.exporters.node.group;
        SocketMode = "0660";
      };
    };

    systemd.services.prometheus-node-exporter.restartTriggers = [
      config.systemd.units.${config.systemd.sockets.prometheus-node-exporter.name}.unit
    ];

    cloud.ghostunnel.servers.spiffe-prometheus-node-exporter = {
      listen = "[::]:9317";
      target = "unix:/run/prometheus-node-exporter.sock";
      allowURIs = [ "spiffe://nichi.link/victoriametrics" ];
    };

    cloud.services.spiffe-prometheus-node-exporter.config.SupplementaryGroups = [
      config.services.prometheus.exporters.node.group
    ];

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

    cloud.ghostunnel.clients.spiffe-systemd-journal-upload = {
      listen = "systemd:spiffe-systemd-journal-upload";
      target = "logs.nichi.co:9429";
      verifyURI = "spiffe://nichi.link/victorialogs";
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
