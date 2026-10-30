{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./stalwart.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
