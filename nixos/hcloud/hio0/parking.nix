{ lib, ... }:
let
  inherit (lib) singleton;
  mkRoute = host: location: {
    match = singleton { host = singleton host; };
    handle = singleton {
      handler = "static_response";
      status_code = "302";
      headers = {
        Location = singleton location;
      };
    };
  };
in
{
  cloud.caddy.settings.apps.http.servers.default.routes = [
    (mkRoute "nixos.zip" "https://channels.nixos.org/nixos-unstable")
  ];
}
