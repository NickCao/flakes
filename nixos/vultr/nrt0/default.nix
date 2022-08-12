{ config, pkgs, lib, ... }:
{
  imports = [
    ../common.nix
    ./configuration.nix
    ./services.nix
  ];
}
