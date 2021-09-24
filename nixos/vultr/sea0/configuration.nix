{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = { };
  };
  networking = {
    hostName = "sea0";
    domain = "nichi.link";
  };
  services.dns = {
    enable = true;
  };
}
