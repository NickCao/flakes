{
  config,
  lib,
  ...
}:
let
  cfg = config.services.metrics;
  certDir = "/var/lib/caddy/certificates/ca.nichi.co-8443-acme-acme-directory";
  certBase = "${certDir}/${config.networking.fqdn}/${config.networking.fqdn}";
in
{
  options.services.metrics = {
    enable = lib.mkEnableOption "export server metrics";
  };
  config = lib.mkIf cfg.enable {
    sops.secrets.metrics = {
      sopsFile = ./secrets.yaml;
      restartUnits = [ "caddy.service" ];
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = [ config.sops.secrets.metrics.path ];

    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "arp" ];
    };

    cloud.caddy.settings.apps.http.servers.default.routes = [
      {
        match = [
          {
            host = [ config.networking.fqdn ];
            path = [ "/metrics" ];
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
            upstreams = with config.services.prometheus.exporters.node; [
              { dial = "${listenAddress}:${toString port}"; }
            ];
          }
        ];
      }
    ];

    systemd.services.systemd-journal-upload.serviceConfig = {
      RefreshOnReload = [ "credentials" ];
      LoadCredential = [
        "key:${certBase}.key"
        "crt:${certBase}.crt"
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
