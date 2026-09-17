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

    systemd.services.systemd-journal-upload.serviceConfig = {
      RefreshOnReload = [ "credentials" ];
      LoadCredential = [
        "key:${config.passthru.hostKey}"
        "crt:${config.passthru.hostCrt}"
      ];
    };

    services.journald.upload = {
      enable = true;
      settings.Upload = {
        URL = "https://logs.nichi.co:443/insert/journald";
        NetworkTimeoutSec = "5m";
        Compression = "zstd:4";
        ForceCompression = true;
        TrustedCertificateFile = "${config.security.pki.caBundle}";
        ServerKeyFile = "/run/credentials/systemd-journal-upload.service/key";
        ServerCertificateFile = "/run/credentials/systemd-journal-upload.service/crt";
      };
    };
  };
}
