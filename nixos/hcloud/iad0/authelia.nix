{ config, pkgs, ... }:
let
  cfg = config.services.authelia.instances.default;
in
{

  sops.secrets = {
    authelia-jwt = { owner = cfg.user; };
    authelia-storage = { owner = cfg.user; };
    authelia-users = { owner = cfg.user; };
  };

  services.authelia.instances.default = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia-storage.path;
    };
    settings = {
      server = {
        host = "127.0.0.1";
        port = 8005;
      };
      session = {
        domain = "nichi.co";
      };
      storage = {
        local = {
          path = "/var/lib/authelia-default/db.sqlite3";
        };
      };
      notifier = {
        filesystem = {
          filename = "/var/lib/authelia-default/notification.txt";
        };
      };
      authentication_backend = {
        file = {
          path = config.sops.secrets.authelia-users.path;
        };
      };
      access_control = {
        default_policy = "two_factor";
      };
    };
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers.authelia = {
          rule = "Host(`id.nichi.co`)";
          entryPoints = [ "https" ];
          service = "authelia";
        };
        services.authelia.loadBalancer = {
          passHostHeader = true;
          servers = [{
            url = "http://${cfg.settings.server.host}:${toString cfg.settings.server.port}";
          }];
        };
      };
    };
  };

}
