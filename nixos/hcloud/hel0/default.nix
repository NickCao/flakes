{ ... }:
{

  imports = [
    ../common.nix
    ./vaultwarden.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  system.stateVersion = "24.11";

}
