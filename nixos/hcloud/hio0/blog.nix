{ config, pkgs, ... }: {

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [{
        host = [ "nichi.co" ];
        path = [ "/.well-known/matrix/server" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = 200;
        headers = {
          Access-Control-Allow-Origin = [ "*" ];
          Content-Type = [ "application/json" ];
        };
        body = builtins.toJSON {
          "m.server" = "matrix.nichi.co:443";
        };
      }];
    }
    {
      match = [{
        host = [ "nichi.co" ];
        path = [ "/.well-known/matrix/client" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = 200;
        headers = {
          Access-Control-Allow-Origin = [ "*" ];
          Content-Type = [ "application/json" ];
        };
        body = builtins.toJSON {
          "m.homeserver" = {
            "base_url" = config.services.matrix-synapse.settings.public_baseurl;
          };
        };
      }];
    }
    {
      match = [{
        host = [ "nichi.co" ];
        path = [ "/.well-known/webfinger" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = "302";
        headers = {
          Access-Control-Allow-Origin = [ "*" ];
          Location = [ "https://${config.services.mastodon.extraConfig.WEB_DOMAIN}{http.request.uri}" ];
        };
      }];
    }
    {
      match = [{
        host = [ "nichi.co" ];
      }];
      handle = [
        {
          handler = "headers";
          response.set = {
            Strict-Transport-Security = [ "max-age=31536000; includeSubDomains; preload" ];
          };
        }
        {
          handler = "file_server";
          root = "${pkgs.blog}";
        }
      ];
    }
  ];

}
