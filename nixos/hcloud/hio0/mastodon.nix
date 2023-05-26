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

}
