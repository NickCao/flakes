{ lib, ... }: {

  imports = [
    ../common.nix
    ./prometheus.nix
    ./ntfy.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "lax0";

  services.gateway.enable = lib.mkForce false;

  cloud.caddy.enable = true;

}
