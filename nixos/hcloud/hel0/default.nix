{ ... }:
{

  imports = [
    ../common.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
