{ pkgs, lib, config, ... }:
let
  caddyConfig = (pkgs.formats.json { }).generate "config.json" {
    admin = {
      disabled = true;
      config = {
        persist = false;
      };
    };
    logging = {
      sink = {
        writer = {
          output = "stdout";
        };
      };
      logs = {
        default = {
          level = "DEBUG";
        };
      };
    };
    apps = {
      tls = {
        automation = {
          policies = [{
            on_demand = true;
            key_type = "p256";
          }];
        };
      };
      http = {
        servers = {
          default = {
            listen = [ ":443" ];
            routes = [
              {
                match = [{
                  host = [ "ntfy.nichi.co" ];
                }];
                handle = [{
                  handler = "reverse_proxy";
                  upstreams = [{ dial = "unix/${config.services.ntfy-sh.settings.listen-unix}"; }];
                }];
              }
              {
                match = [{
                  host = [ config.networking.fqdn ];
                  path = [ "/prom" "/prom/*" ];
                }];
                handle = [{
                  handler = "reverse_proxy";
                  upstreams = [{ dial = "${config.services.prometheus.listenAddress}:${builtins.toString config.services.prometheus.port}"; }];
                }];
              }
            ];
          };
        };
      };
    };
  };
in
{

  imports = [
    ../common.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "lax0";

  services.gateway.enable = lib.mkForce false;

  systemd.services.caddy = {
    serviceConfig = {
      ExecStart = "${pkgs.caddy-nickcao}/bin/caddy run --adapter jsonc --config ${caddyConfig}";
      DynamicUser = true;
      StateDirectory = "caddy";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      Environment = [ "XDG_DATA_HOME=%S" ];
    };
    wantedBy = [ "multi-user.target" ];
  };

}
