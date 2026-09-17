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
    ./ports.nix
    { cloud.caddy.selfsigned = true; }
  ];

  sops.defaultSopsFile = ./secrets.yaml;

}
