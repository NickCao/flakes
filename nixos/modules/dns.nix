{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.dns;
in
{
  options.services.dns = {
    enable = mkEnableOption "gravity dns service";
    recursive = mkOption {
      type = types.bool;
      default = true;
      description = "recursive dns";
    };
    nat64 = mkOption {
      type = types.str;
      description = "nat64 prefix";
    };
    zsk = mkOption {
      type = types.str;
      description = "base path to zsk";
      default = "/etc/coredns/zsk";
    };
  };
  config = mkIf cfg.enable {
    environment.etc = {
      "coredns/zones/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa".source = pkgs.fetchurl {
        url = "https://s3.nichi.co/artifacts/gravity/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa";
        sha256 = "sha256-S4ev2aZhvbceE+M9mdvmSuu16O61zuT1EpgWg0nIMog=";
      };
      "coredns/zones/db.gravity".source = pkgs.fetchurl {
        url = "https://s3.nichi.co/artifacts/gravity/db.gravity";
        sha256 = "sha256-Dm0UMjEeIcDezdeRW2kIXqSGUwOPbNaWPsBOjJ3AqlY=";
      };
    };

    services.coredns.enable = true;
    services.coredns.config = ''
      nichi.co {
        file ${pkgs."db.co.nichi"}
      }
      nichi.link {
        file ${pkgs."db.link.nichi"}
      }
    '' + optionalString cfg.recursive ''
      . {
        auto {
          directory /etc/coredns/zones
        }
        dns64 {
          prefix ${cfg.nat64}
        }
        acl 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
          allow
        }
        acl . {
          allow net 2a0c:b641:69c::/48 2001:470:4c22::/48
          block
        }
        dnssec 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
          key file ${cfg.zsk}
        }
        forward . 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
      }
    '';
  };
}
