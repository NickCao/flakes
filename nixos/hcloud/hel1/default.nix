{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./radicle.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
