{ config, lib, pkgs, ... }:
let
  cgitFilters = "${pkgs.cgit-pink}/lib/cgit/filters";
  cgitrc = pkgs.writeText "cgitrc" ''
    root-title=nichi yorozuya
    root-desc=¯\_(ツ)_/¯
    logo=
    source-filter=${cgitFilters}/syntax-highlighting.py
    about-filter=${cgitFilters}/about-formatting.sh
    css=/custom.css
    clone-prefix=https://git.nichi.co
    scan-path=${config.users.users.git.home}
  '';
  cgitWebroot = "${pkgs.cgit-pink}/cgit";
  lighttpdConfig = pkgs.writeText "lighttpd.conf" ''
    server.bind = "127.0.0.1"
    server.port = 8006
    server.document-root = "${pkgs.cgit-pink}/cgit"
    server.modules += ( "mod_cgi", "mod_alias", "mod_setenv" )

    include "${pkgs.lighttpd}/share/lighttpd/doc/config/conf.d/mime.conf"

    cgi.assign = ( "cgit.cgi" => "" )
    alias.url = (
      "/robots.txt"  => "${cgitWebroot}/robots.txt",
      "/custom.css"  => "${./cgit.css}",
      "/cgit.css"    => "${cgitWebroot}/cgit.css",
      "/cgit.png"    => "${cgitWebroot}/cgit.png",
      ""             => "${cgitWebroot}/cgit.cgi",
    )
    setenv.add-environment = ( "CGIT_CONFIG" => "${cgitrc}" )
  '';
in
{
  cloud.services.cgit.config = {
    ExecStart = "${pkgs.lighttpd}/bin/lighttpd -D -f ${lighttpdConfig}";
    PrivateUsers = false;
    ProtectHome = "tmpfs";
    BindReadOnlyPaths = config.users.users.git.home;
  };

  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    description = "git";
    home = "/home/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    ];
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
