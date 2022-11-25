{ config, pkgs, ... }:
let
  cgitFilters = "${pkgs.cgit-pink}/lib/cgit/filters";
  cgitrc = pkgs.writeText "cgitrc" ''
    root-title=nichi yorozuya
    root-desc=¯\_(ツ)_/¯
    logo=
    source-filter=${cgitFilters}/syntax-highlighting.py
    about-filter=${cgitFilters}/about-formatting.sh
    readme=:README.md
    snapshots=tar.zst
    css=/custom.css
    clone-prefix=https://git.nichi.co
    section-from-path=1
    remove-suffix=1
    scan-path=${config.users.users.git.home}
  '';
  cgitWebroot = "${pkgs.cgit-pink}/cgit";
  lighttpdConfig = pkgs.writeText "lighttpd.conf" ''
    server.bind = "127.0.0.1"
    server.port = 8006
    server.document-root = "/var/empty"
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
    BindReadOnlyPaths = config.users.users.git.home;
  };

  cloud.services.cgit-mirror.enable = false;
  cloud.services.cgit-mirror.config = {
    User = "git";
    ExecStart = "${pkgs.gh-mirror}/bin/gh-mirror --exclude-forks --include nixpkgs NickCao";
    BindPaths = config.users.users.git.home;
    WorkingDirectory = "${config.users.users.git.home}/mirror";
  };

  systemd.timers.cgit-mirror = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "hourly";
  };

  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    description = "git";
    home = "/var/lib/git";
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = pkgs.keys;
  };

  systemd.tmpfiles.rules = [ "d /var/lib/git 0755 git git - -" ];

  services.traefik.dynamicConfigOptions.http = {
    routers.git = {
      rule = "Host(`git.nichi.co`)";
      entryPoints = [ "https" ];
      service = "cgit";
    };
    services.cgit.loadBalancer = {
      passHostHeader = true;
      servers = [{ url = "http://127.0.0.1:8006"; }];
    };
  };

}
