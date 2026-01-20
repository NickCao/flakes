{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.radicle;
in
{
  sops.secrets.radicle = {
    owner = config.systemd.services.radicle-node.serviceConfig.User;
    reloadUnits = [ config.systemd.services.radicle-node.name ];
  };

  services.radicle = {
    enable = true;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlHxjllfArJcmd91uPmKTlrA0BqjAOyINhlkARvMQmO radicle";
    privateKeyFile = config.sops.secrets.radicle.path;
    node = {
      listenAddress = "[::]";
      listenPort = 8776;
    };
    httpd = {
      enable = true;
      listenAddress = "127.0.0.1";
      listenPort = 8080;
      aliases = { };
    };
    settings = {
      node = {
        alias = "radicle.nichi.co";
        externalAddresses = [
          "${cfg.settings.node.alias}:${toString cfg.node.listenPort}"
        ];
        relay = "always";
        seedingPolicy = {
          default = "block";
        };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton cfg.settings.node.alias; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton { dial = "${cfg.httpd.listenAddress}:${toString cfg.httpd.listenPort}"; };
    };
  };
}
