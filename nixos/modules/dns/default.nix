{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.dns;
  zones = {
    "db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa" = pkgs.fetchurl {
      url = "https://s3.nichi.co/artifacts/gravity/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa";
      sha256 = "sha256-Cb27SL3Te73I02bU6tFQ/UOWt7uH8p68fvBrx7sLQVc=";
    };
    "db.gravity" = pkgs.fetchurl {
      url = "https://s3.nichi.co/artifacts/gravity/db.gravity";
      sha256 = "sha256-ryqiDBjwILGHQsmSk9cr/ypW+dJyYKJp2QN0P5GXBac=";
    };
  };
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
    sops.secrets = builtins.listToAttrs (flatten (builtins.map
      (x: [
        { name = "${x}.key"; value = { mode = "0444"; sopsFile = ./secrets.yaml; }; }
        { name = "${x}.private"; value = { mode = "0444"; sopsFile = ./secrets.yaml; }; }
      ]) [
      "Knichi.co.+013+41694"
      "Knichi.link.+013+43698"
      "K9.6.0.1.4.6.b.c.0.a.2.ip6.arpa.+013+13716"
    ]));
    services.coredns.enable = true;
    systemd.services.coredns.restartTriggers = [ (builtins.hashFile "sha256" ./secrets.yaml) ];
    services.coredns.config = ''
      nichi.co {
        file ${pkgs."db.co.nichi"}
        dnssec {
          key file /run/secrets/Knichi.co.+013+41694
        }
      }
      nichi.link {
        file ${pkgs."db.link.nichi"}
        dnssec {
          key file /run/secrets/Knichi.link.+013+43698
        }
      }
      9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
        file ${zones."db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa"}
        dnssec {
          key file /run/secrets/K9.6.0.1.4.6.b.c.0.a.2.ip6.arpa.+013+13716
        }
      }
    '' + optionalString (cfg.nat64 != "") ''
      . {
        file ${zones."db.gravity"} gravity
        dns64 {
          prefix ${cfg.nat64}
        }
        acl . {
          allow net 2a0c:b641:69c::/48 2001:470:4c22::/48
          block
        }
        forward . 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
      }
    '';
  };
}
