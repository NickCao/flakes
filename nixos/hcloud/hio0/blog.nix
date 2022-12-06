{ config, pkgs, ... }: {

  cloud.services.blog.config = {
    ExecStart = "${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 -p 8007 --index index.html ${pkgs.blog}";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.blog = {
      rule = "Host(`nichi.co`)";
      entryPoints = [ "https" ];
      middlewares = [ "blog" ];
      service = "blog";
    };
    middlewares.blog.headers = {
      stsSeconds = 31536000;
      stsIncludeSubdomains = true;
      stsPreload = true;
    };
    services.blog.loadBalancer = {
      servers = [{ url = "http://127.0.0.1:8007"; }];
    };
  };

}
