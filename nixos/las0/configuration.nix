{ pkgs, config, ... }:
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

  services.powerdns.enable = true;
}
