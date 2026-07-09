{ ... }:
{

  imports = [
    ../common.nix
    ./services.nix
    ./prometheus.nix
    ./ntfy.nix
    ./victorialogs.nix
    ./acme-dns.nix
    ./stalwart.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
