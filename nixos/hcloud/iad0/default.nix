{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
    ./vaultwarden.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
