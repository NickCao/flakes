{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.cloud.caddy;
  format = pkgs.formats.json { };
  configfile = format.generate "config.json" cfg.settings;
in
{

  options = {
    cloud.caddy = {
      enable = lib.mkEnableOption "caddy api gateway";
      settings = lib.mkOption {
        type = lib.types.submodule { freeformType = format.type; };
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    cloud.caddy.settings = {
      admin = {
        listen = "unix//tmp/caddy.sock";
        config.persist = false;
      };
      apps = {
        tls.automation.policies = [ { key_type = "p256"; } ];
        http.grace_period = "1s";
        http.servers.default = {
          listen = [ ":443" ];
          strict_sni_host = false;
          routes = [
            {
              match = [
                {
                  host = [ config.networking.fqdn ];
                  path = [ "/caddy" ];
                }
              ];
              handle = [
                {
                  handler = "authentication";
                  providers.http_basic.accounts = [
                    {
                      username = "prometheus";
                      password = "{env.PROM_PASSWD}";
                    }
                  ];
                }
                { handler = "metrics"; }
              ];
            }
          ];
          metrics = { };
        };
      };
    };

    environment.etc."caddy/config.json".source = configfile;

    systemd.services.caddy = {
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.caddy-nickcao}/bin/caddy run --config /etc/caddy/config.json";
        ExecReload = "${pkgs.caddy-nickcao}/bin/caddy reload --force --config /etc/caddy/config.json";
        DynamicUser = true;
        StateDirectory = "caddy";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        Environment = [ "XDG_DATA_HOME=%S" ];
      };
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "network-online.target"
      ];
      requires = [ "network-online.target" ];
      reloadTriggers = [ configfile ];
    };
  };
}
