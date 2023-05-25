{ config, pkgs, ... }: {

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nichi.co";
      listen-http = "";
      listen-unix = "/var/lib/ntfy-sh/ntfy.sock";
      listen-unix-mode = 511; # 0777
      behind-proxy = true;
    };
  };

}
