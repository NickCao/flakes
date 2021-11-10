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
    sops.secrets = builtins.listToAttrs
      (flatten (builtins.map
        (x: [
          { name = "${x}.key"; value = { mode = "0444"; sopsFile = ./secrets.yaml; restartUnits = [ "coredns.service" ]; }; }
          { name = "${x}.private"; value = { mode = "0444"; sopsFile = ./secrets.yaml; restartUnits = [ "coredns.service" ]; }; }
        ]) [
        "Knichi.co.+013+41694"
        "Knichi.link.+013+43698"
        "K9.6.0.1.4.6.b.c.0.a.2.ip6.arpa.+013+13716"
      ])) // {
      gravity = { mode = "0444"; sopsFile = ./secrets.yaml; restartUnits = [ "coredns.service" ]; };
      gravity_reverse = { mode = "0444"; sopsFile = ./secrets.yaml; restartUnits = [ "coredns.service" ]; };
    };
    services.coredns.enable = true;
    services.coredns.package = pkgs.coredns.overrideAttrs (_: {
      patches = [
        ./coredns.patch
        (pkgs.fetchurl {
          url = "https://github.com/coredns/coredns/commit/1915767109c5ac3533326a5d595657428dd1ee85.patch";
          sha256 = "sha256-/uTQFg41KJTedF2VtdBcFIylzWcOM/cpt7LUXZ4xvHo=";
        })
      ];
      preBuild = ''
        go generate -mod=vendor coredns.go
      '';
    });
    services.coredns.config = ''
      nichi.co {
        file ${pkgs."db.co.nichi"}
        dnssec {
          key file /run/secrets/Knichi.co.+013+41694
        }
      }
      nichi.link {
        etcd dyn.nichi.link {
            fallthrough
            path /dns
            endpoint https://etcd.nichi.co:443
            credentials coredns coredns
        }
        file ${pkgs."db.link.nichi"}
        dnssec {
          key file /run/secrets/Knichi.link.+013+43698
        }
      }
      9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
        file ${config.sops.secrets.gravity_reverse.path}
        dnssec {
          key file /run/secrets/K9.6.0.1.4.6.b.c.0.a.2.ip6.arpa.+013+13716
        }
      }
    '' + optionalString (cfg.nat64 != "") ''
      . {
        file ${config.sops.secrets.gravity.path} gravity
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
