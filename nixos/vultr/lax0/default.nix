{ ... }: {

  imports = [
    ../common.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "lax0";

}
