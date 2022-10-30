{ pkgs, config, ... }:
{
  cloud.services.fn.config = {
    ExecStart = "${pkgs.deno}/bin/deno run --allow-env --allow-net --no-check ${../../../fn}/index.ts";
    EnvironmentFile = config.sops.secrets.woff.path;
    MemoryDenyWriteExecute = false;
    Environment = [ "PORT=8001" "DENO_DIR=/tmp" ];
  };

  cloud.services.workerd.config = {
    ExecStart = "${pkgs.workerd}/bin/workerd serve --import-path=/ ${pkgs.writeText "config.capnp" ''
      using Workerd = import "/workerd/workerd.capnp";

      const config :Workerd.Config = (
        services = [
          (name = "rants", worker = .rants),
          (name = "gravity", disk = "/var/lib/gravity"),
        ],

        sockets = [
          ( name = "http",
            address = "127.0.0.1:8002",
            http = (),
            service = "rants"
          ),
          ( name = "http",
            address = "127.0.0.1:8003",
            http = (),
            service = "gravity"
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
            rule = "Host(`api.nichi.co`) && Path(`/rait`)";
            middlewares = [ "rait0" "rait1" ];
            service = "rait";
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
          rait0.replacePath = {
            path = "/registry.json";
          };
          rait1.basicAuth = {
            users = [ "{{ env `RAIT_PASSWD` }}" ];
            removeheader = true;
          };
          rants.stripPrefix.prefixes = [ "/rants" ];
        };
        services = {
          rants.loadBalancer.servers = [{ url = "http://127.0.0.1:8002"; }];
          fn.loadBalancer.servers = [{ url = "http://127.0.0.1:8001"; }];
          rait.loadBalancer.servers = [{ url = "http://127.0.0.1:8003";  }];
        };
      };
    };
  };
}
