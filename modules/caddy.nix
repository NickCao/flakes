{
  pkgs,
  config,
  lib,
  data,
  ...
}:
let
  cfg = config.cloud.caddy;
  format = pkgs.formats.json { };
  configfile = format.generate "config.json" cfg.settings;
  inherit (data.nodes."${config.networking.hostName}") ipv4 ipv6;
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
            profile = "shortlived";
            challenges = {
              http.disabled = true;
            };
          };
        };
        http = {
          grace_period = "1s";
          metrics = { };
          servers.default = {
            listen = [
              "fdname/${config.systemd.sockets.caddy-h2.name}"
              "fdgramname/${config.systemd.sockets.caddy-h3.name}"
            ];
            listen_protocols = [
              [
                "h1"
                "h2"
              ]
              [ "h3" ]
            ];
            strict_sni_host = false;
            routes = [
              {
                match = [
                  {
                    host = [
                      config.networking.fqdn
                      ipv4
                      ipv6
                    ];
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
          };
        };
      };
    };

    environment.etc."caddy/config.json".source = configfile;

    systemd.sockets.caddy-h2 = {
      socketConfig = {
        ListenStream = [ "443" ];
        Service = config.systemd.services.caddy.name;
      };
      wantedBy = [ "sockets.target" ];
    };

    systemd.sockets.caddy-h3 = {
      socketConfig = {
        ListenDatagram = [ "443" ];
        Service = config.systemd.services.caddy.name;
      };
      wantedBy = [ "sockets.target" ];
    };

    systemd.services.caddy = {
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.caddy-nickcao}/bin/caddy run --config /etc/caddy/config.json";
        ExecReload = "${pkgs.caddy-nickcao}/bin/caddy reload --force --config /etc/caddy/config.json";
        DynamicUser = true;
        StateDirectory = [ "caddy" ];
        RuntimeDirectory = [ "caddy" ];
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
        CapabilityBoundingSet = "";
      };
      reloadTriggers = [ configfile ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
    };
  };
}
