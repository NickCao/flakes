{ ... }:
{

  imports = [
    ../common.nix
    ./vaultwarden.nix
    ./rustical.nix
    ./litestream.nix
    ./step-ca.nix
    { cloud.caddy.selfsigned = true; }
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  system.stateVersion = "24.11";

}
