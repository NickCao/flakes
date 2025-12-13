{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
