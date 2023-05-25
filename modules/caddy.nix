{ pkgs, config, lib }:
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
        default = {
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
            };
          };
        };
        type = format.type;
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
