{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./mailpit.nix
    ./victorialogs.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
