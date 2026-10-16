{ ... }:
{
  services.spire.server = {
    enable = true;
    settings = {
      server = {
        audit_log_enabled = true;
        bind_address = "[::]";
        bind_port = 9443;
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
          allowed_dns_patterns = [ "[a-z0-9]{1,63}\.nichi\.link" ];
          required_port = 81;
          tofu = false;
          # verify_client_ip = true;
        };
      };
    };
  };
}
