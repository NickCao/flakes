{ pkgs, config, ... }:
{
  cloud.services.fn.config = {
    ExecStart = "${pkgs.python3.withPackages (ps: with ps; [ uvicorn fastapi ])}/bin/python ${../../../fn/index.py}";
    Environment = [ "PORT=8001" ];
  };

  cloud.services.workerd.config = {
    ExecStart = "${pkgs.workerd}/bin/workerd serve --import-path=/ ${pkgs.writeText "config.capnp" ''
      using Workerd = import "/workerd/workerd.capnp";

      const config :Workerd.Config = (
        services = [
          (name = "rants", worker = .rants),
        ],

        sockets = [
          ( name = "http",
            address = "127.0.0.1:8002",
            http = (),
            service = "rants"
          ),
        ]
      );

      const rants :Workerd.Worker = (
        serviceWorkerScript = embed "${../../../fn/rants.js}",
        compatibilityDate = "2022-09-16",
      );
    ''}";
    Environment = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
    MemoryDenyWriteExecute = false;
  };

  systemd.services.traefik.serviceConfig.EnvironmentFile = config.sops.secrets.traefik.path;
  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          rait = {
            rule = "Host(`api.nichi.co`, `fn.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait" ];
            service = "fn";
          };
          fn = {
            rule = "Host(`fn.nichi.co`)";
            service = "fn";
          };
          rants = {
            rule = "Host(`fn.nichi.co`) && PathPrefix(`/rants`)";
            middlewares = [ "rants" ];
            service = "rants";
          };
        };
        middlewares = {
          rait.basicAuth = {
            users = [ "{{ env `RAIT_PASSWD` }}" ];
            removeheader = true;
          };
          rants.stripPrefix.prefixes = [ "/rants" ];
        };
        services = {
          rants.loadBalancer.servers = [{ url = "http://127.0.0.1:8002"; }];
          fn.loadBalancer.servers = [{ url = "http://127.0.0.1:8001"; }];
        };
      };
    };
  };
}
