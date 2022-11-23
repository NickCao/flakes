{ config, ... }:
{
  imports = [
    ../common.nix
    ./prometheus.nix
  ];
  sops.defaultSopsFile = ./secrets.yaml;
  networking.hostName = "lax0";
}
