{ config, pkgs, lib, ... }: {

  sops.secrets = {
    tsig = { owner = "knot"; sopsFile = ../../zones/secrets.yaml; };
    gravity = { owner = "knot"; sopsFile = ../../zones/secrets.yaml; };
    gravity_reverse = { owner = "knot"; sopsFile = ../../zones/secrets.yaml; };
  };

  services.knot = {
    enable = true;
    keyFiles = [ config.sops.secrets.tsig.path ];
    extraConfig = builtins.readFile ./knot.conf + ''
      zone:
        - domain: firstparty
          template: catalog
        - domain: nichi.co
          file: ${pkgs."db.co.nichi"}
          dnssec-signing: off
        - domain: nichi.link
          file: ${pkgs."db.link.nichi"}
        - domain: scp.link
          file: ${pkgs."db.link.scp"}
        - domain: gravity
          file: ${config.sops.secrets.gravity.path}
          dnssec-signing: off
        - domain: 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa
          file: ${config.sops.secrets.gravity_reverse.path}
    '';
  };

}
