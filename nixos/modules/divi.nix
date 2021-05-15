{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.divi;
in
{
  options.services.divi = {
    enable = mkEnableOption "divi nat64";
    prefix = mkOption {
      type = types.str;
      description = "nat64 prefix";
    };
    address = mkOption {
      type = types.str;
      description = "nat64 address";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.divi = {
      serviceConfig = {
        ExecStart = "${pkgs.tayga}/bin/tayga -d --config ${pkgs.writeText "tayga.conf" ''
          tun-device divi
          ipv4-addr 10.208.0.2
          prefix ${cfg.prefix}
          dynamic-pool 10.208.0.0/12
          data-dir /var/spool/tayga
        ''}";
      };
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };
    systemd.network.networks = {
      divi = {
        name = "divi";
        addresses = [
          {
            addressConfig = {
              Address = "10.208.0.1/12";
              PreferredLifetime = 0;
            };
          }
          {
            addressConfig = {
              Address = cfg.address;
              PreferredLifetime = 0;
            };
          }
        ];
        routes = [
          {
            routeConfig = {
              Destination = cfg.prefix;
            };
          }
        ];
      };
    };
  };
}
