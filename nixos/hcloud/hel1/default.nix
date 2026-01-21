{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./radicle.nix
    ./mailpit.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
