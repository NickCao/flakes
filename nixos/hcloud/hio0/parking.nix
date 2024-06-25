{ ... }:
let
  mkRoute = host: location: {
    match = [ { host = [ host ]; } ];
    handle = [
      {
        handler = "static_response";
        status_code = "302";
        headers = {
          Location = [ location ];
        };
      }
    ];
  };
in
{
  cloud.caddy.settings.apps.http.servers.default.routes = [
    (mkRoute "wikipedia.zip" "https://www.wikipedia.org/wiki/Wikipedia:Database_download")
    (mkRoute "nixos.zip" "https://channels.nixos.org/nixos-unstable")
    (mkRoute "archlinux.icu" "https://manjaro.org")
    (mkRoute "nixos.icu" "https://archlinux.org")
    (mkRoute "systemd.services" "https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html")
  ];
}
