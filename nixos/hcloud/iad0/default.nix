{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
    ./stalwart.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
