{ pkgs, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    ../common.nix
    ./knot.nix
    ./postfix.nix
    ./dovecot.nix
    ./vaultwarden.nix
    ./kanidm.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "iad0";

}
