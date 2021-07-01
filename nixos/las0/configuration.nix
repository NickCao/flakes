{ pkgs, config, ... }:
{
  networking = {
    hostName = "las0";
    domain = "nichi.link";
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      minio = { };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };

  services.dns = {
    enable = true;
  };

  systemd.network.networks = {
    ens3 = {
      name = "ens3";
      address = [ "2605:6400:20:387::1/48" ];
      routes = [
        {
          routeConfig = {
            Gateway = "2605:6400:2:fed5::1";
            GatewayOnLink = true;
          };
        }
      ];
    };
  };
}
