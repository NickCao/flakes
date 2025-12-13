{
  config,
  pkgs,
  lib,
  data,
  ...
}:
let
  cfg = config.services.prometheus;
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes;
  nameservers = lib.mapAttrsToList (_mame: value: value.fqdn) (
    lib.filterAttrs (_name: value: lib.elem "nameserver" value.tags) data.nodes
  );
  relabel_configs = [
    {
      source_labels = [ "__address__" ];
      target_label = "__param_target";
    }
    {
      source_labels = [ "__param_target" ];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement =
        with config.services.prometheus.exporters.blackbox;
        "${listenAddress}:${toString port}";
    }
  ];
in
{
  sops.secrets = {
    prometheus = {
      owner = config.systemd.services.prometheus.serviceConfig.User;
      restartUnits = [ "prometheus.service" ];
    };
    telegram = {
      restartUnits = [ "alertmanager.service" ];
    };
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${config.networking.fqdn}/prom";
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "7d";
    globalConfig = {
      scrape_interval = "1m";
      evaluation_interval = "1m";
    };
    scrapeConfigs = [
      {
        job_name = "metrics";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "caddy";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        metrics_path = "/caddy";
        static_configs = [ { inherit targets; } ];
      }
      {
        job_name = "dns";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "dns_soa" ];
        };
        static_configs = [ { targets = nameservers; } ];
        inherit relabel_configs;
      }
      {
        job_name = "http";
        scheme = "http";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        static_configs = [
          {
            targets = [
              "https://nichi.co"
              "https://matrix.nichi.co"
            ];
          }
        ];
        inherit relabel_configs;
      }
    ];
    rules = lib.singleton (
      builtins.toJSON {
        groups = [
          {
            name = "metrics";
            rules = [
              {
                alert = "NodeDown";
                expr = ''up == 0'';
                for = "5m";
              }
              {
                alert = "OOM";
                expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1'';
              }
              {
                alert = "DiskFull";
                expr = ''node_filesystem_avail_bytes{mountpoint=~"/persist"} / node_filesystem_size_bytes < 0.1'';
              }
              {
                alert = "UnitFailed";
                expr = ''node_systemd_unit_state{state="failed"} == 1'';
              }
              {
                alert = "ZoneStale";
                expr = ''probe_dns_serial{instance="iad0.nichi.link"} != ignoring(instance) group_right() probe_dns_serial'';
                for = "5m";
              }
            ];
          }
        ];
      }
    );
    alertmanagers = [
      {
        path_prefix = "/alert";
        static_configs = [
          { targets = [ "${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}" ]; }
        ];
      }
    ];
    alertmanager = {
      enable = true;
      webExternalUrl = "https://${config.networking.fqdn}/alert";
      listenAddress = "127.0.0.1";
      port = 9093;
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [
          {
            name = "telegram";
            telegram_configs = [
              {
                bot_token_file = "/run/credentials/alertmanager.service/telegram";
                chat_id = 893182727;
              }
            ];
          }
        ];
        route = {
          receiver = "telegram";
        };
      };
    };
  };

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "telegram:${config.sops.secrets.telegram.path}"
  ];

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    configFile = (pkgs.formats.yaml { }).generate "config.yml" {
      modules = {
        http_2xx = {
          prober = "http";
        };
        dns_soa = {
          prober = "dns";
          dns = {
            query_name = "nichi.co";
            query_type = "SOA";
          };
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [
        {
          host = [ config.networking.fqdn ];
          path = [
            "/prom"
            "/prom/*"
          ];
        }
      ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "${cfg.listenAddress}:${builtins.toString cfg.port}"; } ];
        }
      ];
    }
  ];
}
