{ ... }: {

  imports = [
    ../common.nix
    ./blog.nix
    ./matrix.nix
    ./services.nix
    ./pb.nix
    ./mastodon.nix
    ./keycloak.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "hio0";

}
