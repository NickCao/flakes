{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
