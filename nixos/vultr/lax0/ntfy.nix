{ config, pkgs, ... }: {

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.nichi.co";
      listen-http = "127.0.0.1:8008";
      behind-proxy = true;
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.ntfy = {
      rule = "Host(`ntfy.nichi.co`)";
      entryPoints = [ "https" ];
      service = "ntfy";
    };
    services.ntfy.loadBalancer = {
      passHostHeader = true;
      servers = [{ url = "http://${config.services.ntfy-sh.settings.listen-http}"; }];
    };
  };

}
