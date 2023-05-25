{ pkgs, lib, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
    ./vaultwarden.nix
    ./authelia.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "iad0";

}
