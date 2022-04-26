{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      ranet.reloadUnits = [ "gravity.service" ];
      woff = { };
      traefik = { };
    };
  };
  networking.hostName = "nrt0";
  services.dns.secondary.enable = true;
  services.gravity-ng = {
    enable = true;
    reload.enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:7860::1/128" ];
    bird = {
      enable = true;
      exit.enable = true;
      prefix = "2a0c:b641:69c:7860::/60";
    };
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:7864:0:4::/96";
    };
  };
}
