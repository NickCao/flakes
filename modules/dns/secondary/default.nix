{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.dns.secondary;
in
{
  options.services.dns.secondary = {
    enable = mkEnableOption "secondary dns service";
  };
  config = mkIf cfg.enable {
    sops.secrets.tsig = { sopsFile = ./secrets.yaml; owner = "knot"; };
    services.knot = {
      enable = true;
      keyFiles = [ config.sops.secrets.tsig.path ];
      extraConfig = builtins.readFile ./knot.conf;
    };
  };
}
