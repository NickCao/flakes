{ config, lib, pkgs, ... }:
let
  cgitrc = pkgs.writeText "cgitrc" ''
    css=/custom.css
  '';
  cgit = "${pkgs.cgit-pink}/cgit";
  lighttpdConfig = pkgs.writeText "lighttpd.conf" ''
    server.port = 8006
    server.document-root = "${pkgs.cgit-pink}/cgit"
    server.modules += ( "mod_cgi", "mod_alias", "mod_setenv" )

    include "${pkgs.lighttpd}/share/lighttpd/doc/config/conf.d/mime.conf"

    cgi.assign = ( "cgit.cgi" => "" )
    alias.url = (
      "/custom.css" => "${./cgit.css}",
      "/cgit.css" => "${cgit}/cgit.css",
      "/cgit.png" => "${cgit}/cgit.png",
      "/favicon.ico" => "${cgit}/cgit.png",
      "" => "${cgit}/cgit.cgi",
    )
    setenv.add-environment = ( "CGIT_CONFIG" => "${cgitrc}" )
  '';
in
{
  cloud.services.cgit.config = {
    ExecStart = "${pkgs.lighttpd}/bin/lighttpd -D -f ${lighttpdConfig}";
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        git = {
          rule = "Host(`git.nichi.co`)";
          entryPoints = [ "https" ];
          service = "cgit";
        };
      };
      services = {
        cgit.loadBalancer = {
          passHostHeader = true;
          servers = [{ url = "http://127.0.0.1:8006"; }];
        };
      };
    };
  };
}
