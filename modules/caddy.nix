{ pkgs, config, lib, ... }:
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
        type = lib.types.submodule {
          freeformType = format.type;
        };
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    cloud.caddy.settings = {
      admin = {
        disabled = true;
        config.persist = false;
      };
      apps = {
        tls.automation.policies = [{
          on_demand = true;
          key_type = "p256";
        }];
        http.servers.default = {
          listen = [ ":443" ];
          tls_connection_policies = [{
            match = { sni = [ "*.nichi.link" "*.nichi.co" "nichi.co" "wikipedia.zip" ]; };
          }];
          routes = [{
            match = [{
              host = [ config.networking.fqdn ];
              path = [ "/caddy" ];
            }];
            handle = [{
              handler = "metrics";
            }];
          }];
        };
      };
    };

    systemd.services.caddy = {
      serviceConfig = {
        ExecStart = "${pkgs.caddy-nickcao}/bin/caddy run --adapter jsonc --config ${configfile}";
        DynamicUser = true;
        StateDirectory = "caddy";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        Environment = [ "XDG_DATA_HOME=%S" ];
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

}
