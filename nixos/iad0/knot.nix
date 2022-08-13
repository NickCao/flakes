{ config, pkgs, lib, inputs, ... }: {

  sops.secrets = {
    tsig = { owner = "knot"; reloadUnits = [ "knot.service" ]; sopsFile = ../../zones/secrets.yaml; };
    gravity = { owner = "knot"; reloadUnits = [ "knot.service" ]; sopsFile = ../../zones/secrets.yaml; };
    gravity_reverse = { owner = "knot"; reloadUnits = [ "knot.service" ]; sopsFile = ../../zones/secrets.yaml; };
  };

  services.knot = {
    enable = true;
    keyFiles = [ config.sops.secrets.tsig.path ];
    extraConfig = builtins.readFile ./knot.conf + ''
      zone:
        - domain: firstparty
          template: catalog
        - domain: nichi.co
          file: ${pkgs.writeText "db.co.nichi" (import ../../zones/nichi.co.nix { inherit (inputs) dns; })}
          dnssec-signing: off
        - domain: nichi.link
          file: ${pkgs.writeText "db.link.nichi" (import ../../zones/nichi.link.nix { inherit (inputs) dns; })}
        - domain: scp.link
          file: ${pkgs.writeText "db.link.scp" (import ../../zones/scp.link.nix { inherit (inputs) dns; })}
        - domain: gravity
          file: ${config.sops.secrets.gravity.path}
          dnssec-signing: off
        - domain: 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa
          file: ${config.sops.secrets.gravity_reverse.path}
    '';
  };

}
