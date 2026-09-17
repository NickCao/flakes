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
    { cloud.caddy.selfsigned = false; }
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
