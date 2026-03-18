{ config, lib, ... }:
let
  cfg = config.services.metrics;
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

    sops.secrets.vlagent = {
      sopsFile = ./secrets.yaml;
      mode = "0440";
      group = config.users.groups.vlagent-secrets.name;
      restartUnits = [ config.systemd.services.vlagent.name ];
    };

    users.groups.vlagent-secrets = { };

    systemd.services.vlagent.serviceConfig.SupplementaryGroups = [ config.users.groups.vlagent-secrets.name ];

    services.vlagent = {
      enable = true;
      extraArgs = [
        "-httpListenAddr=127.0.0.1:9429"
        "-remoteWrite.maxDiskUsagePerURL=500MB"
        "-remoteWrite.basicAuth.username=vlagent"
        "-remoteWrite.basicAuth.passwordFile=${config.sops.secrets.vlagent.path}"
      ];
      remoteWrite = {
        url = "https://logs.nichi.co/insert/native";
      };
    };

    services.journald.upload = {
      enable = true;
      settings.Upload = {
        URL = "http://127.0.0.1:9429/insert/journald";
        NetworkTimeoutSec = "5m";
        Compression = "zstd:4";
        ForceCompression = true;
      };
    };
  };
}
