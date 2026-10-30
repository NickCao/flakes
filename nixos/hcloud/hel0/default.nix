{ ... }:
{
  imports = [
    ../common.nix
    ./vaultwarden.nix
    ./spire.nix
    ./openbao.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  system.stateVersion = "24.11";
}
