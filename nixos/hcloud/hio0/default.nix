{ ... }:
{

  imports = [
    ../common.nix
    ./blog.nix
    ./matrix.nix
    ./draupnir.nix
    ./pb.nix
    ./mastodon.nix
    ./miniflux.nix
    ./keycloak.nix
    ./parking.nix
    ./ports.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
