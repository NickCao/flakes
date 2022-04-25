{ config, pkgs, ... }:
{
  sops.secrets.ranet.reloadUnits = [ "gravity.service" ];
  services.gravity-ng = {
    enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:99cc::1/128" ];
    bird = {
      leaf.enable = true;
      prefix = "2a0c:b641:69c:99cc::/64";
      pattern = "grv*";
    };
  };

  systemd.services.v2ray = {
    description = "a platform for building proxies to bypass network restrictions";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      LoadCredential = "secret.json:${config.sops.secrets.v2ray.path}";
      DynamicUser = true;
      ExecStart = "${pkgs.v2ray}/bin/v2ray run -c ${(pkgs.formats.json {}).generate "config.json" (import ./v2ray.nix)} -c \${CREDENTIALS_DIRECTORY}/secret.json";
    };
  };
}
