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
    extraConfig = builtins.readFile ./knot.conf + ''
      zone:
        - domain: firstparty
          template: catalog
        - domain: nichi.co
          file: ${pkgs.writeText "db.co.nichi" (import ../../../zones/nichi.co.nix { inherit (inputs) dns; })}
        - domain: nichi.link
          file: ${pkgs.writeText "db.link.nichi" (import ../../../zones/nichi.link.nix { inherit (inputs) dns; inherit lib; })}
        - domain: scp.link
          file: ${pkgs.writeText "db.link.scp" (import ../../../zones/scp.link.nix { inherit (inputs) dns; })}
        - domain: wikipedia.zip
          file: ${pkgs.writeText "db.zip.wikipedia" (import ../../../zones/parking.nix { inherit (inputs) dns; })}
        - domain: nixos.zip
          file: ${pkgs.writeText "db.zip.nixos" (import ../../../zones/parking.nix { inherit (inputs) dns; })}
        - domain: gravity
          file: ${config.sops.secrets.gravity.path}
          dnssec-signing: off
        - domain: 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa
          file: ${config.sops.secrets.gravity_reverse.path}
    '';
  };

}
