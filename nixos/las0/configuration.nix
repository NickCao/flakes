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
      n8n = {
        sopsFile = ./secrets.yaml;
      };
    };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
}
