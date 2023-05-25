{ pkgs, lib, config, ... }: {

  imports = [
    ../common.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "lax0";

  services.gateway.enable = lib.mkForce false;

  cloud.caddy = {
    enable = true;
    settings = {
      apps.http.servers.default.routes = [
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

}
