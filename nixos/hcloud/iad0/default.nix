{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./stalwart.nix
    ./litestream.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
