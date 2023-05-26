{ config, pkgs, lib, ... }: {

  services.mastodon = {
    enable = true;
    localDomain = "nichi.co";
    smtp = {
      createLocally = false;
      fromAddress = "mastodon@nichi.co";
    };
    extraConfig = {
      WEB_DOMAIN = "mastodon.nichi.co";
    };
  };

  systemd.services.caddy.serviceConfig.SupplementaryGroups = [ "mastodon" ];

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ "mastodon.nichi.co" ];
    }];
    handle = [
      {
        handler = "file_server";
        root = "${pkgs.mastodon}/public";
        pass_thru = true;
      }
      {
        handler = "reverse_proxy";
        upstreams = [{ dial = "unix//run/mastodon-web/web.socket"; }];
      }
    ];
  }];


}
