{ lib, config, ... }:
let
  cfg = config.services.spire.server.settings.server;
in
{
  services.spire.server = {
    enable = true;
    settings = {
      server = {
        audit_log_enabled = true;
        bind_address = "127.0.0.1";
        bind_port = 6059;
        proxy_protocol_trusted_cidrs = [ "127.0.0.1/32" ];
        trust_domain = "nichi.link";
        ca_subject = {
          country = [ "US" ];
          organization = [ "Nichi Yorozuya" ];
          common_name = "SPIRE";
        };
      };
      plugins = {
        DataStore.sql.plugin_data = {
          database_type = "sqlite3";
          connection_string = "/var/lib/spire/server/datastore.sqlite3";
        };
        KeyManager.disk.plugin_data = {
          keys_path = "/var/lib/spire/server/keys.json";
        };
        NodeAttestor.http_challenge.plugin_data = {
          allowed_dns_patterns = [ "[a-z0-9]{,63}\.nichi\.link" ];
          required_port = 81;
          tofu = false;
          verify_client_ip = true;
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "spire.nichi.co"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      transport = {
        protocol = "http";
        proxy_protocol = "v2";
        tls.insecure_skip_verify = true;
      };
      upstreams = lib.singleton {
        dial = "${cfg.bind_address}:${toString cfg.bind_port}";
      };
    };
  };
}
