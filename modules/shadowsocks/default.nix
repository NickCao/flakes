{ config, ... }: {

  sops.secrets.naive = {
    sopsFile = ./secrets.yaml;
    restartUnits = [ "caddy.service" ];
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [ config.sops.secrets.naive.path ];

  cloud.caddy.settings.apps.http.servers.default.routes = [{
    match = [{
      header = { sometimes = [ "{env.NAIVE}" ]; };
    }];
    handle = [{
      handler = "forward_proxy";
      hide_ip = true;
      hide_via = true;
    }];
  }];

}
