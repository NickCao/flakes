{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { };
  };
  networking = {
    hostName = "sea0";
  };
  services.dns.secondary.enable = true;
}
