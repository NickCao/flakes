{ pkgs, config, modulesPath, self, inputs, ... }: {

  cloud.services.meow.config = {
    ExecStart = "${pkgs.meow}/bin/meow --listen 127.0.0.1:8002 --base-url https://pb.nichi.co --data-dir \${STATE_DIRECTORY}";
    StateDirectory = "meow";
    SystemCallFilter = null;
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.meow = {
      rule = "Host(`pb.nichi.co`)";
      entryPoints = [ "https" ];
      service = "meow";
    };
    services.meow.loadBalancer = {
      passHostHeader = true;
      servers = [{ url = "http://127.0.0.1:8002"; }];
    };
  };

}
