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
        listen = "unix//run/caddy/caddy.sock";
        config.persist = false;
      };
      apps = {
        tls.automation.policies = lib.singleton {
          disable_ocsp_stapling = true;
          key_type = "p256";
          issuers = lib.singleton {
            module = "acme";
            profile = "tlsserver";
          };
        };
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
                  providers.http_basic = {
                    accounts = [
                      {
                        username = "prometheus";
                        password = "{env.PROM_PASSWD}";
                      }
                    ];
                    hash_cache = { };
                  };
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
        StateDirectory = [ "caddy" ];
        RuntimeDirectory = [ "caddy" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        Environment = [ "XDG_DATA_HOME=%S" ];
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        ProtectSystem = "strict";
        ProtectControlGroups = "strict";
        ProtectKernelModules = true;
        LockPersonality = true;
        ProtectKernelTunables = true;
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";
        PrivateDevices = true;
        ProtectClock = true;
        ProtectKernelLogs = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
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
