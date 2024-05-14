{ ... }:
{

  imports = [
    ../common.nix
    ./blog.nix
    ./matrix.nix
    ./pb.nix
    ./mastodon.nix
    ./miniflux.nix
    ./keycloak.nix
    ./parking.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "hio0";

  fileSystems."/data" = {
    device = "/dev/disk/by-partlabel/DATA";
    fsType = "btrfs";
    options = [ "compress-force=zstd" ];
  };
}
