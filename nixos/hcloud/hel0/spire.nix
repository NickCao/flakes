{ ... }:
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
      };
    };
  };
}
