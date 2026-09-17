{ ... }:
{

  imports = [
    ../common.nix
    ./vaultwarden.nix
    ./rustical.nix
    ./litestream.nix
    ./step-ca.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  system.stateVersion = "24.11";

}
