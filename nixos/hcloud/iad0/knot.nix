{ config, pkgs, lib, inputs, ... }: {

  sops.secrets = {
    tsig = {
      owner = config.systemd.services.knot.serviceConfig.User;
      reloadUnits = [ "knot.service" ];
      sopsFile = ../../../zones/secrets.yaml;
    };
    gravity = {
      owner = config.systemd.services.knot.serviceConfig.User;
      reloadUnits = [ "knot.service" ];
      sopsFile = ../../../zones/secrets.yaml;
    };
    gravity_reverse = {
      owner = config.systemd.services.knot.serviceConfig.User;
      reloadUnits = [ "knot.service" ];
      sopsFile = ../../../zones/secrets.yaml;
    };
  };

  services.knot = {
    enable = true;
    keyFiles = [ config.sops.secrets.tsig.path ];
    settings = {
      server = {
        async-start = true;
        edns-client-subnet = true;
        tcp-fastopen = true;
        tcp-reuseport = true;
        listen = [ "0.0.0.0" "::" ];
      };
      log = [{
        target = "syslog";
        any = "info";
      }];
      acl = [{
        action = "transfer";
        id = "transfer";
        key = "transfer";
      }];
      policy = [{
        algorithm = "ed25519";
        id = "default";
        ksk-lifetime = "365d";
        ksk-shared = true;
        ksk-submission = "default";
        nsec3 = true;
        nsec3-iterations = "10";
        signing-threads = "12";
      }];
      remote = [{
        address = [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
        id = "cloudflare";
      }];
      submission = [{
        check-interval = "10m";
        id = "default";
        parent = "cloudflare";
      }];
      template = [
        {
          acl = "transfer";
          catalog-role = "member";
          catalog-zone = "firstparty";
          dnssec-policy = "default";
          dnssec-signing = true;
          id = "default";
          journal-content = "all";
          semantic-checks = true;
          serial-policy = "unixtime";
          zonefile-load = "difference-no-serial";
          zonefile-sync = "-1";
          zonemd-generate = "zonemd-sha512";
        }
        {
          acl = "transfer";
          catalog-role = "generate";
          id = "catalog";
          journal-content = "all";
          serial-policy = "unixtime";
          zonefile-load = "difference-no-serial";
          zonefile-sync = "-1";
        }
      ];
      zone = [
        {
          domain = "firstparty";
          template = "catalog";
        }
        {
          domain = "nichi.co";
          file = pkgs.writeText "db.co.nichi" (import ../../../zones/nichi.co.nix {
            inherit (inputs) dns;
          });
        }
        {
          domain = "nichi.link";
          file = pkgs.writeText "db.link.nichi" (import ../../../zones/nichi.link.nix { inherit (inputs) dns; inherit lib; });
        }
        {
          domain = "scp.link";
          file = pkgs.writeText "db.link.scp" (import ../../../zones/scp.link.nix {
            inherit (inputs) dns;
          });
        }
        {
          domain = "wikipedia.zip";
          file = pkgs.writeText "db.zip.wikipedia" (import ../../../zones/parking.nix { inherit (inputs) dns; });
        }
        {
          domain = "nixos.zip";
          file = pkgs.writeText "db.zip.nixos" (import ../../../zones/parking.nix { inherit (inputs) dns; });
        }
        {
          domain = "gravity";
          file = config.sops.secrets.gravity.path;
          dnssec-signing = false;
        }
        {
          domain = "9.6.0.1.4.6.b.c.0.a.2.ip6.arpa";
          file = config.sops.secrets.gravity_reverse.path;
        }
      ];
    };
  };

}
