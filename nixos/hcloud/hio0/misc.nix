{ pkgs, config, modulesPath, self, inputs, ... }: {

  services.libreddit = {
    enable = true;
    address = "127.0.0.1";
    port = 34123;
  };

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      host = [ "red.nichi.co" ];
    }];
    handle = [{
      handler = "reverse_proxy";
      upstreams = [{ dial = "${config.services.libreddit.address}:${toString config.services.libreddit.port}"; }];
    }];
  }];

}
