{ config, lib, ... }:
{
  services.mailpit.instances.default = {
    listen = "127.0.0.1:8024";
    smtp = "127.0.0.1:8025";
    max = 1000;
    database = "mailpit.db";
    hide-delete-all-button = true;
    smtp-allowed-recipients = ''(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@scp.link'';
  };

  systemd.sockets.caddy-mailpit = {
    socketConfig = {
      ListenStream = [ "25" ];
      Service = config.systemd.services.caddy.name;
    };
    wantedBy = [ "sockets.target" ];
  };

  cloud.caddy.settings.apps.layer4.servers.mailpit = {
    listen = lib.singleton "fdname/${config.systemd.sockets.caddy-mailpit.name}";
    routes = lib.singleton {
      handle = lib.singleton {
        handler = "proxy";
        upstreams = lib.singleton { dial = lib.singleton config.services.mailpit.instances.default.smtp; };
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = lib.singleton {
    match = lib.singleton { host = lib.singleton "mail.scp.link"; };
    handle = lib.singleton {
      handler = "reverse_proxy";
      upstreams = lib.singleton {
        dial = config.services.mailpit.instances.default.listen;
      };
    };
  };
}
