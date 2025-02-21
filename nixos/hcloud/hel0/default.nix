{ ... }:
{
  imports = [
    ../common.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "hel0";
}
