{
  config,
  pkgs,
  lib,
  data,
  utils,
  ...
}:
let
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes ++ [
    "armchair.nichi.link"
    "subframe.nichi.link"
  ];
  node_exporter_targets = lib.map (v: "${v}:9317") targets;
  caddy_targets = lib.map (v: "${v}:9319") targets;
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
  spiffe_tls_config = {
    ca_file = "/var/lib/victoriametrics/svid_bundle.pem";
    cert_file = "/var/lib/victoriametrics/svid.pem";
    key_file = "/var/lib/victoriametrics/svid_key.pem";
  };
in
{
  sops.secrets.telegram = {
    restartUnits = [ "alertmanager.service" ];
  };

  systemd.services.victoriametrics = {
    serviceConfig = {
      RestartSec = lib.mkForce 10;
      EnvironmentFile = [ "-%t/victoriametrics/credentials" ];
    };
    path = [ pkgs.getent ]; # for bao agent
    preStart = ''
      ${lib.getExe' pkgs.spire "spire-agent"} api fetch jwt \
        -audience openbao \
        -socketPath /run/spire/agent/public/api.sock \
        -output json | ${lib.getExe pkgs.jq} -r '.[0].svids.[0].svid' \
        > /run/victoriametrics/token
      ${lib.getExe pkgs.openbao} agent -exit-after-auth \
        -config ${pkgs.writeText "victoriametrics-openbao-agent.hcl" ''
          vault {
            address = "http://127.0.0.1:8200"
          }
          auto_auth {
            method "jwt" {
              mount_path = "auth/spiffe"
              config {
                path = "/run/victoriametrics/token"
                role = "victoriametrics"
              }
            }
          }
          template {
            perms = "0600"
            contents = <<EOT
          {{ with secret "secrets/scaleway_cockpit_par" }}
          SCW_COCKPIT_PAR_URL={{ .Data.data.url }}
          SCW_COCKPIT_PAR_SECRET_KEY={{ .Data.data.secret_key }}
          {{ end }}
          EOT
            destination = "/run/victoriametrics/credentials"
          }
        ''}
    '';
  };

  cloud.services.spiffe-victoriametrics.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.spiffe-helper)
      "-config"
      ((pkgs.formats.json { }).generate "spiffe-victoriametrics.json" {
        agent_address = "/run/spire/agent/public/api.sock";
        cert_dir = "/var/lib/victoriametrics";
        svid_file_name = "svid.pem";
        svid_key_file_name = "svid_key.pem";
        svid_bundle_file_name = "svid_bundle.pem";
      })
    ];
    StateDirectory = [ "victoriametrics" ];
  };

  services.victoriametrics = {
    enable = true;
    extraOptions = [
      "-vmalert.proxyURL=http://${config.services.vmalert.instances.default.settings."httpListenAddr"}"
      "-opentelemetry.usePrometheusNaming"
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
          tls_config = spiffe_tls_config // {
            server_name = "prometheus-node-exporter.nichi.link";
          };
          static_configs = [ { targets = node_exporter_targets; } ];
        }
        {
          job_name = "caddy";
          scheme = "https";
          tls_config = spiffe_tls_config // {
            server_name = "caddy.nichi.link";
          };
          static_configs = [ { targets = caddy_targets; } ];
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
        {
          job_name = "ups";
          scheme = "https";
          metrics_path = "/ups_metrics";
          tls_config = spiffe_tls_config // {
            server_name = "prometheus-nut-exporter.nichi.link";
          };
          static_configs = [ { targets = [ "subframe.nichi.link:9318" ]; } ];
        }
        {
          job_name = "scw-par";
          honor_labels = true;
          scheme = "https";
          metrics_path = "/federate";
          authorization = {
            type = "Bearer";
            credentials = "%{SCW_COCKPIT_PAR_SECRET_KEY}";
          };
          params."match[]" = [ ''{region="fr-par"}'' ];
          static_configs = [
            { targets = [ "%{SCW_COCKPIT_PAR_URL}" ]; }
          ];
        }
      ];
    };
  };

  services.vmalert.instances.default = {
    enable = true;
    settings = {
      "httpListenAddr" = "127.0.0.1:9134";
      "external.url" = "https://metrics.nichi.co/";
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
              alert = "ProbeFail";
              expr = "probe_success == 0";
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
              expr = ''node_systemd_unit_state{state="activating", name!="restic-backups-persist.service"} == 1'';
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
            {
              alert = "ConntrackFull";
              expr = "node_nf_conntrack_entries / node_nf_conntrack_entries_limit > 0.8";
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

  cloud.caddy.mtls = lib.singleton "metrics.nichi.co";
  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "metrics.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton { dial = "${config.services.victoriametrics.listenAddress}"; };
    };
  };
}
