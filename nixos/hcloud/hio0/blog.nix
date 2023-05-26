{ config, pkgs, ... }:
let
  conf = {
    default_server_config = {
      "m.homeserver" = {
        base_url = "https://nichi.co";
        server_name = "nichi.co";
      };
    };
    brand = "Nichi Yorozuya";
    show_labs_settings = true;
  };
in
{

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [{
        host = [ "nichi.co" ];
        path = [ "/.well-known/webfinger" ];
      }];
      handle = [
        {
          handler = "headers";
          response.set = {
            Access-Control-Allow-Origin = [ "*" ];
          };
        }
        {
          handler = "static_response";
          status_code = "302";
          headers = {
            Location = [ "https://mastodon.nichi.co{http.request.uri}" ];
          };
        }
      ];
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
    {
      match = [{
        host = [ "matrix.nichi.co" ];
      }];
      handle = [{
        handler = "file_server";
        root = "${pkgs.element-web.override { inherit conf; }}";
      }];
    }
    {
      match = [{
        host = [ "wikipedia.zip" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = "302";
        headers = {
          Location = [ "https://www.wikipedia.org/wiki/Wikipedia:Database_download" ];
        };
      }];
    }
  ];

}
