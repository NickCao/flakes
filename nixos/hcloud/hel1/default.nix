{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./mailpit.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
