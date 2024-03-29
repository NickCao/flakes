{ config, pkgs, lib, data, ... }:
let
  cfg = config.services.prometheus;
  targets = lib.mapAttrsToList (_mame: node: node.fqdn) data.nodes ++ [
    "hydra.nichi.link"
  ];
in
{
  sops.secrets = {
    alert = { };
    prometheus = {
      owner = config.systemd.services.prometheus.serviceConfig.User;
      restartUnits = [ "prometheus.service" ];
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
        static_configs = [{ inherit targets; }];
      }
      {
        job_name = "caddy";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        metrics_path = "/caddy";
        static_configs = [{ inherit targets; }];
      }
      {
        job_name = "dns";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        metrics_path = "/probe";
        params = {
          module = [ "dns_soa" ];
          target = [ "1.0.0.1" ];
        };
        static_configs = [{ inherit targets; }];
        relabel_configs = [{
          source_labels = [ "__param_target" ];
          target_label = "target";
        }];
      }
      {
        job_name = "http";
        scheme = "https";
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets.prometheus.path;
        };
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
          target = [ "https://nichi.co" ];
        };
        static_configs = [{ inherit targets; }];
        relabel_configs = [{
          source_labels = [ "__param_target" ];
          target_label = "target";
        }];
      }
    ];
    rules = lib.singleton (builtins.toJSON {
      groups = [{
        name = "metrics";
        rules = [
          {
            alert = "NodeDown";
            expr = ''up == 0'';
          }
          {
            alert = "OOM";
            expr = ''node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1'';
          }
          {
            alert = "DiskFull";
            expr = ''node_filesystem_avail_bytes{mountpoint=~"/persist|/data"} / node_filesystem_size_bytes < 0.1'';
          }
          {
            alert = "UnitFailed";
            expr = ''node_systemd_unit_state{state="failed"} == 1'';
          }
        ];
      }];
    });
    alertmanagers = [{
      path_prefix = "/alert";
      static_configs = [{
        targets = [ "${cfg.alertmanager.listenAddress}:${builtins.toString cfg.alertmanager.port}" ];
      }];
    }];
    alertmanager = {
      enable = true;
      webExternalUrl = "https://${config.networking.fqdn}/alert";
      listenAddress = "127.0.0.1";
      port = 9093;
      extraFlags = [ ''--cluster.listen-address=""'' ];
      configuration = {
        receivers = [{
          name = "ntfy";
          webhook_configs = [{
            url = "https://ntfy.nichi.co/alert?tpl=yes&m=${lib.escapeURL ''
              Alert {{.status}}
              {{range .alerts}}-----{{range $k,$v := .labels}}
              {{$k}}={{$v}}{{end}}
              {{end}}
            ''}";
          }];
        }];
        route = {
          receiver = "ntfy";
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ config.networking.fqdn ];
      path = [ "/prom" "/prom/*" ];
    }];
    handle = [{
      handler = "reverse_proxy";
      upstreams = [{ dial = "${cfg.listenAddress}:${builtins.toString cfg.port}"; }];
    }];
  }];

}
