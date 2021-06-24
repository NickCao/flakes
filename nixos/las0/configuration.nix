{ pkgs, config, ... }:
let
  named = pkgs.writeText "named.conf" ''
    zone "nichi.co" {
      file "${../modules/db.co.nichi}";
    };
  '';
in
{
  networking = {
    hostName = "las0";
    domain = "nichi.link";
  };

  sops = {
    defaultSopsFile = ../modules/secrets.yaml;
    secrets = {
      minio = {
        sopsFile = ./secrets.yaml;
      };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };

  services.powerdns = {
    enable = true;
    extraConfig = ''
      launch=bind
      bind-config=${named}
      resolver=1.1.1.1:53
      expand-alias=yes
    '';
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
