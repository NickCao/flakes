{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { };
    sshKeyPaths = [ "/var/lib/sops.key" ];
  };
  networking = {
    hostName = "sea0";
    domain = "nichi.link";
  };
  services.dns = {
    enable = true;
  };
  services.cluster = {
    enable = true;
    datacenter = "us";
    servers = [ "nrt0.nichi.link" "sin0.nichi.link" "sea0.nichi.link" ];
  };
}
