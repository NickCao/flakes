{ config, pkgs, ... }:
let
  cfg = config.services.authelia.instances.default;
in
{

  sops.secrets = {
    authelia-jwt = { owner = cfg.user; };
    authelia-storage = { owner = cfg.user; };
    authelia-oidc = { owner = cfg.user; };
    authelia-users = { owner = cfg.user; };
  };

  services.authelia.instances.default = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia-jwt.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia-storage.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia-oidc.path;
    };
    settings = {
      theme = "grey";
      default_2fa_method = "webauthn";
      totp.disable = true;
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
        password_reset.disable = true;
        file.path = config.sops.secrets.authelia-users.path;
      };
      access_control = {
        default_policy = "two_factor";
      };
      identity_providers.oidc = {
        clients = [
          {
            id = "synapse";
            description = "Synapse";
            public = true;
            authorization_policy = "two_factor";
            redirect_uris = [ "https://matrix.nichi.co/_synapse/client/oidc/callback" ];
            scopes = [ "openid" "profile" "email" ];
            userinfo_signing_algorithm = "none";
          }
          {
            id = "mastodon";
            secret = "$pbkdf2-sha512$310000$c8p78n7pUMln0jzvd4aK4Q$JNRBzwAo0ek5qKn50cFzzvE9RXV88h1wJn5KGiHrD0YKtZaR/nCb2CJPOsKaPK0hjf.9yHxzQGZziziccp6Yng";
            description = "Mastodon";
            public = false;
            authorization_policy = "two_factor";
            redirect_uris = [ "https://mastodon.nichi.co/auth/auth/openid_connect/callback" ];
            scopes = [ "openid" "profile" "email" ];
            userinfo_signing_algorithm = "none";
          }
        ];
      };
    };
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ "id.nichi.co" ];
    }];
    handle = [{
      handler = "reverse_proxy";
      upstreams = [{ dial = "${cfg.settings.server.host}:${toString cfg.settings.server.port}"; }];
    }];
  }];

}
