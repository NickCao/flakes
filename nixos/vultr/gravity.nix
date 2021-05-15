{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = {};
      bird = {
        path = "/etc/bird.conf";
      };
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
    "coredns/zones/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa".source = pkgs.fetchurl {
      url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com/gravity/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa";
      sha256 = "sha256-v2SG5+qhlfV81zk1vAOnKy3n7nwk3NQgDGK7NfDUnNk=";
    };
    "coredns/zones/db.gravity".source = pkgs.fetchurl {
      url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com/gravity/db.gravity";
      sha256 = "sha256-d1JVsiXqwybYBg4p/TEkmvniCSVOUlc+bU3jMv81RjE=";
    };
  };
  services.divi = {
    enable = true;
    prefix = "2a0c:b641:69c:e0d4:0:4::/96";
    address = "2a0c:b641:69c:e0d4:0:5:0:3/128";
  };
  systemd.services.bird = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      StartLimitIntervalSec = 0;
      ExecStart = "${pkgs.bird2}/bin/bird -d -c /etc/bird.conf";
    };
  };
  services.gravity = {
    enable = true;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:e0d0::1/126";
    group = 54;
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:e0d0::2/126 dev gravity"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 54 suppress_ifgroup 54 pref 1024"
    ];
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
