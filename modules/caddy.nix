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
    MIIB4DCCAYegAwIBAgIRAJcwTG2ONvZSkBUK5BaV+t0wCgYIKoZIzj0EAwIwOjEX
    MBUGA1UEChMOTmljaGkgWW9yb3p1eWExHzAdBgNVBAMTFk5pY2hpIFlvcm96dXlh
    IFJvb3QgQ0EwHhcNMjYwOTE3MDI0NjE5WhcNMzYwOTE0MDI0NjE5WjBCMRcwFQYD
    VQQKEw5OaWNoaSBZb3JvenV5YTEnMCUGA1UEAxMeTmljaGkgWW9yb3p1eWEgSW50
    ZXJtZWRpYXRlIENBMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEsP6Ndy2m23x8
    /TYQ21n5jRv6tG2Yih8Pp02Qm8MXHzDR4Fxnm9hRUA2iaNVRRRxyb9QmVoW6UNnY
    WB5FE59EW6NmMGQwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAw
    HQYDVR0OBBYEFI4+Bt14wcFXkgkR+bFbTMVTCnhzMB8GA1UdIwQYMBaAFP+wQMNW
    k50Tqg/a+TYZwI6chbJmMAoGCCqGSM49BAMCA0cAMEQCIGWQ3V8qwGvZ1nO9HrqE
    mfPXWjzSj7qCroqjOwJwelzAAiAOrT0NL8I+bkvKxazWl/hxsZ/F5Nof6s1U1qyf
    x4n/lw==
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
    passthru = { inherit intermediate; };
    cloud.caddy.settings = {
      admin.disabled = true;
      apps = {
        tls.certificates = {
          automate = lib.singleton config.networking.fqdn;
        };
        tls.automation.policies = [
          {
            subjects = lib.singleton config.networking.fqdn;
            disable_ocsp_stapling = true;
            key_type = "p256";
            issuers = lib.singleton {
              module = "acme";
              ca = "https://ca.nichi.co:8443/acme/acme/directory";
              trusted_roots_pem_files = lib.singleton intermediate;
              challenges = {
                http.disabled = true;
              };
            };
          }
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
            tls_connection_policies = lib.mkAfter [
              {
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
              { }
            ];
            routes = lib.singleton {
              match = lib.singleton {
                host = lib.singleton config.networking.fqdn;
                path = lib.singleton "/caddy";
              };
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
  };
}
