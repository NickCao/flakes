{ ... }:
{

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
    { cloud.caddy.selfsigned = true; }
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
