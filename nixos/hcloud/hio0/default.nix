{ pkgs, lib, config, modulesPath, self, inputs, data, ... }: {

  imports = [
    ../common.nix
    ./blog.nix
    ./matrix.nix
    ./services.nix
    ./pb.nix
    ./misc.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;

  networking.hostName = "hio0";

}
