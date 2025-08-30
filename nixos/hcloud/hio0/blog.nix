{ config, pkgs, ... }:
{

  cloud.caddy.settings.apps.http.servers.default.routes = [
    {
      match = [
        {
          host = [
            "cache.nichi.co"
            "hydra.nichi.co"
          ];
        }
      ];
      handle = [
        {
          handler = "static_response";
          status_code = 404;
          headers = {
            Content-Type = [ "text/plain" ];
          };
          body = "This service is no longer available";
        }
      ];
    }
    {
      match = [
        {
          host = [ "nichi.co" ];
          path = [ "/.well-known/matrix/server" ];
        }
      ];
      handle = [
        {
          handler = "static_response";
          status_code = 200;
          headers = {
            Access-Control-Allow-Origin = [ "*" ];
            Content-Type = [ "application/json" ];
          };
          body = builtins.toJSON { "m.server" = "matrix.nichi.co:443"; };
        }
      ];
    }
    {
      match = [
        {
          host = [ "nichi.co" ];
          path = [ "/.well-known/matrix/client" ];
        }
      ];
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [ { dial = "127.0.0.1:${toString config.lib.ports.synapse}"; } ];
        }
      ];
    }
    {
      match = [
        {
          host = [ "nichi.co" ];
          path = [ "/.well-known/webfinger" ];
        }
      ];
      handle = [
        {
          handler = "static_response";
          status_code = "302";
          headers = {
            Access-Control-Allow-Origin = [ "*" ];
            Location = [ "https://${config.services.mastodon.extraConfig.WEB_DOMAIN}{http.request.uri}" ];
          };
        }
      ];
    }
    {
      match = [ { host = [ "nichi.co" ]; } ];
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
