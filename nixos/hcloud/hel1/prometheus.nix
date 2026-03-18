{
  config,
  pkgs,
  lib,
  data,
  ...
}:
let
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes ++ [ "subframe.nichi.link" ];
  ipv4_targets = lib.mapAttrsToList (_mame: node: node.ipv4) data.nodes;
  nameservers = data.nameservers ++ data.secondary_nameservers;
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
      mode = "0440";
      group = config.users.groups.victoriametrics-secrets.name;
      restartUnits = [ config.systemd.services.victoriametrics.name ];
    };
    telegram = {
      restartUnits = [ "alertmanager.service" ];
    };
  };

  users.groups.victoriametrics-secrets = { };

  systemd.services.victoriametrics.serviceConfig = {
    SupplementaryGroups = [ config.users.groups.victoriametrics-secrets.name ];
  };

  services.victoriametrics = {
    enable = true;
    extraOptions = [
      "-vmalert.proxyURL=http://${config.services.vmalert.instances.default.settings."httpListenAddr"}"
    ];
    listenAddress = "127.0.0.1:9090";
    retentionPeriod = "7d";
    prometheusConfig = {
      global = {
        scrape_interval = "1m";
      };
      scrape_configs = [
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
          static_configs = [ { targets = ipv4_targets; } ];
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
          job_name = "dns_cds";
          scheme = "http";
          metrics_path = "/probe";
          params = {
            module = [ "dns_cds" ];
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
                "https://id.nichi.co"
                "https://fn.nichi.co"
                "https://pb.nichi.co"
                "https://api.nichi.co"
                "https://cal.nichi.co"
                "https://rss.nichi.co"
                "https://ntfy.nichi.co"
                "https://vault.nichi.co"
                "https://matrix.nichi.co"
                "https://matrix-auth.nichi.co"
                "https://bouncer.nichi.co"
                "https://mastodon.nichi.co"
              ];
            }
          ];
          inherit relabel_configs;
        }

      ];
    };
  };

  services.vmalert.instances.default = {
    enable = true;
    settings = {
      "httpListenAddr" = "127.0.0.1:9134";
      "external.url" = "https://${config.networking.fqdn}/alert";
      "datasource.url" = "http://${config.services.victoriametrics.listenAddress}";
      "notifier.url" = [
        "http://${config.services.prometheus.alertmanager.listenAddress}:${builtins.toString config.services.prometheus.alertmanager.port}"
      ];
    };
    rules = {
      groups = [
        {
          name = "metrics";
          rules = [
            {
              alert = "NodeDown";
              expr = "up == 0";
              for = "5m";
            }
            {
              alert = "OOM";
              expr = "node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1";
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
              alert = "UnitActivating";
              expr = ''node_systemd_unit_state{state="activating"} == 1'';
              for = "15m";
            }
            {
              alert = "ZoneFail";
              expr = "probe_dns_query_succeeded != 1";
              for = "5m";
            }
            {
              alert = "ZoneStale";
              expr = ''probe_dns_serial{instance="iad0.nichi.link"} != ignoring(instance) group_right() probe_dns_serial'';
              for = "5m";
            }
            {
              alert = "ZoneHasCDS";
              expr = ''probe_dns_answer_rrs{job="dns_cds"} != 0'';
            }
            {
              alert = "CertExpiring";
              expr = "probe_ssl_earliest_cert_expiry - time() < 24*3600";
              for = "5m";
            }
          ];
        }
      ];
    };
  };

  services.prometheus.alertmanager = {
    enable = true;
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
            query_name = "nichi.link";
            query_type = "SOA";
          };
        };
        dns_cds = {
          prober = "dns";
          dns = {
            query_name = "nichi.link";
            query_type = "CDS";
          };
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = lib.singleton {
        host = lib.singleton "metrics.nichi.co";
      };
      handle = [
        {
          handler = "authentication";
          providers.http_basic = {
            accounts = [
              {
                username = "vm";
                password = "{env.VM_PASSWORD}";
              }
            ];
            hash_cache = { };
          };
        }
        {
          handler = "reverse_proxy";
          upstreams = lib.singleton {
            dial = "${config.services.victoriametrics.listenAddress}";
          };
        }
      ];
    }
  ];
}
