{ ... }:
{

  imports = [
    ../common.nix
    ./vaultwarden.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
