{ pkgs, config, modulesPath, self, inputs, ... }: {

  services.libreddit = {
    enable = true;
    address = "127.0.0.1";
    port = 34123;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.libreddit = {
      rule = "Host(`red.nichi.co`)";
      entryPoints = [ "https" ];
      service = "libreddit";
    };
    services.libreddit.loadBalancer = {
      passHostHeader = true;
      servers = [{ url = "http://${config.services.libreddit.address}:${toString config.services.libreddit.port}"; }];
    };
  };

}
