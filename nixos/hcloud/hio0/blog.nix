{ config, pkgs, ... }: {

  cloud.services.blog.config = {
    ExecStart = "${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 -p 8007 --hidden --index index.html ${pkgs.blog}";
  };

  cloud.services.element-web.config =
    let
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://nichi.co";
            server_name = "nichi.co";
          };
        };
        brand = "Nichi Yorozuya";
        show_labs_settings = true;
      };
    in
    {
      ExecStart = "${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 -p 8005 --index index.html ${pkgs.element-web.override { inherit conf; }}";
    };


  services.traefik.dynamicConfigOptions.http = {
    routers = {
      blog = {
        rule = "Host(`nichi.co`)";
        entryPoints = [ "https" ];
        middlewares = [ "blog" ];
        service = "blog";
      };
      element = {
        rule = "Host(`matrix.nichi.co`)";
        entryPoints = [ "https" ];
        service = "element";
      };
    };
    middlewares.blog.headers = {
      stsSeconds = 31536000;
      stsIncludeSubdomains = true;
      stsPreload = true;
    };
    services = {
      blog.loadBalancer = {
        servers = [{ url = "http://127.0.0.1:8007"; }];
      };
      element.loadBalancer = {
        servers = [{ url = "http://127.0.0.1:8005"; }];
      };
    };
  };

}
