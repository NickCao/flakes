{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = {};
      bird = {};
      private_zsk = {
        mode = "0644";
        path = "/etc/coredns/zsk.private";
      };
      public_zsk = {
        mode = "0644";
        path = "/etc/coredns/zsk.key";
      };
    };
    sshKeyPaths = [ "/var/lib/sops/key" ];
  };
  environment.etc = {
    "rait/babeld.conf".text = ''
      random-id true
      local-path-readwrite /run/babeld.ctl
      state-file ""
      pid-file ""
      interface placeholder
      redistribute local deny
    '';
  };
  systemd.services.coredns = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };
  services.coredns.enable = true;
  services.coredns.config = ''
    . {
      auto {
        directory /etc/coredns/zones
      }
      dns64 {
        prefix 2a0c:b641:69c:e0d4:0:4::/96
      }
      acl 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
        allow
      }
      acl . {
        allow net 2a0c:b641:69c::/48 2001:470:4c22::/48
        block
      }
      dnssec 9.6.0.1.4.6.b.c.0.a.2.ip6.arpa {
        key file /etc/coredns/zsk
      }
      forward . 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
    }
  '';
}
