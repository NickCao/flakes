{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./mailpit.nix
    ./victorialogs.nix
    ./acme-dns.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
