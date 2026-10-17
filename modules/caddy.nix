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
  # TODO: automatic refresh
  intermediate = pkgs.writeText "intermediate.pem" ''
    -----BEGIN CERTIFICATE-----
    MIIBtjCCAV2gAwIBAgIUKVgqjNIpnxn5c9tJ2fIIoWsRx3UwCgYIKoZIzj0EAwIw
    ITEfMB0GA1UEAxMWTmljaGkgWW9yb3p1eWEgVXNlciBDQTAeFw0yNjEwMTcyMTI1
    NDJaFw0yNzEwMTcyMTI2MTJaMDExLzAtBgNVBAMTJk5pY2hpIFlvcm96dXlhIFVz
    ZXIgSW50ZXJtZWRpYXRlIENBIEUxMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
    +MI4eqUkzlw3dgJPshAlC8oAVweDg+2dMdYJAhzgfSggt1MWER+EHBBabBHcP+1B
    7FiOAQjI114Hu5oo78AJtaNjMGEwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
    MAMBAf8wHQYDVR0OBBYEFG4TPle++prkwVre0BIXq1TbtsIlMB8GA1UdIwQYMBaA
    FBJgNbRBVtsErh8pNhtv6q8cuPq2MAoGCCqGSM49BAMCA0cAMEQCIEMGYu8yYU6t
    9WUcIp4zcTgogQrpNsMsQIO/VAvxekwsAiAv18zwJTp3xzsqQmJW699xaP6Sozje
    b6cOe4begeptpw==
    -----END CERTIFICATE-----
  '';
in
{

  options = {
    cloud.caddy = {
      enable = lib.mkEnableOption "caddy api gateway";
      mtls = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      settings = lib.mkOption {
        type = lib.types.submodule { freeformType = format.type; };
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    cloud.caddy.settings = {
      admin.disabled = true;
      apps = {
        tls.automation.policies = [
          {
            disable_ocsp_stapling = true;
            key_type = "p256";
            issuers = lib.singleton {
              module = "acme";
              profile = "shortlived";
              challenges = {
                http.disabled = true;
              };
            };
          }
        ];
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
            strict_sni_host = true;
            tls_connection_policies = lib.mkAfter (
              lib.optional (cfg.mtls != [ ]) {
                match = {
                  sni = cfg.mtls;
                };
                client_authentication = {
                  mode = "require_and_verify";
                  ca = {
                    provider = "file";
                    pem_files = lib.singleton intermediate;
                  };
                };
              }
              ++ [ { } ]
            );
          };
          servers.metrics = {
            listen = [ "unix//run/caddy/metrics.sock|0660" ];
            automatic_https.disable = true;
            routes = lib.singleton {
              match = lib.singleton {
                path = lib.singleton "/metrics";
              };
              handle = lib.singleton { handler = "metrics"; };
            };
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
      requiredBy = [ config.systemd.services.caddy.name ];
    };

    systemd.sockets.caddy-h3 = {
      socketConfig = {
        ListenDatagram = [ "443" ];
        Service = config.systemd.services.caddy.name;
      };
      wantedBy = [ "sockets.target" ];
      requiredBy = [ config.systemd.services.caddy.name ];
    };

    systemd.services.caddy = {
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.caddy-nickcao}/bin/caddy run --config /etc/caddy/config.json";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
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

    systemd.services.spiffe-caddy = {
      wants = [ config.systemd.services.caddy.name ];
      after = [ config.systemd.services.caddy.name ];
    };

    cloud.ghostunnel.servers.spiffe-caddy = {
      listen = "[::]:9319";
      target = "unix:/run/caddy/metrics.sock";
      allowURIs = [ "spiffe://nichi.link/victoriametrics" ];
    };

    cloud.services.spiffe-caddy.config.Group = "caddy";

    cloud.spire.agent.enable = true;
  };
}
