{ ... }: {

  cloud.caddy.settings.apps.http.servers.default.routes = [
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
    {
      match = [{
        host = [ "nixos.zip" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = "302";
        headers = {
          Location = [ "https://channels.nixos.org/nixos-unstable" ];
        };
      }];
    }
    {
      match = [{
        host = [ "archlinux.icu" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = "302";
        headers = {
          Location = [ "https://manjaro.org" ];
        };
      }];
    }
    {
      match = [{
        host = [ "nixos.icu" ];
      }];
      handle = [{
        handler = "static_response";
        status_code = "302";
        headers = {
          Location = [ "https://archlinux.org" ];
        };
      }];
    }
  ];

}
