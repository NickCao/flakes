{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.dns;
in
{
  options.services.dns = {
    enable = mkEnableOption "gravity dns service";
    nat64 = mkOption {
      type = types.str;
      default = "";
      description = "nat64 prefix";
    };
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
