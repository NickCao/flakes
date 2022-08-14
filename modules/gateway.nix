{ lib, config, ... }:
let cfg = config.services.gateway; in
with lib;{
  options = {
    services.gateway = {
      enable = mkEnableOption "traefik api gateway";
    };
  };
  config = mkIf cfg.enable {
    services.traefik = {
      enable = true;
      staticConfigOptions = {
        experimental.http3 = true;
        entryPoints = {
          http = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "https";
              scheme = "https";
              permanent = false;
            };
          };
          https = {
            address = ":443";
            http.tls.certResolver = "le";
            http3 = { };
          };
        };
        certificatesResolvers.le.acme = {
          email = "blackhole@nichi.co";
          storage = config.services.traefik.dataDir + "/acme.json";
          keyType = "EC256";
          tlsChallenge = { };
        };
        ping = {
          manualRouting = true;
        };
        metrics = {
          prometheus = {
            addRoutersLabels = true;
            manualRouting = true;
          };
        };
      };
      dynamicConfigOptions = {
        tls.options.default = {
          minVersion = "VersionTLS13";
          sniStrict = true;
        };
        http = {
          routers = {
            ping = {
              rule = "Host(`${config.networking.fqdn}`) && Path(`/`)";
              entryPoints = [ "https" ];
              service = "ping@internal";
            };
            traefik = {
              rule = "Host(`${config.networking.fqdn}`) && Path(`/traefik`)";
              entryPoints = [ "https" ];
              service = "prometheus@internal";
            };
          };
        };
      };
    };
  };
}
