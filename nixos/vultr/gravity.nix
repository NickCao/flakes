{ pkgs, config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rait = {
        path = "/etc/rait/rait.conf";
      };
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
    "rait/babeld.conf".text = ''
      random-id true
      local-path-readwrite /run/babeld.ctl
      state-file ""
      pid-file ""
      interface placeholder
      redistribute local deny
    '';
    "rait/tayga.conf".text = ''
      tun-device divi
      ipv4-addr 10.208.0.2
      prefix 2a0c:b641:69c:e0d4:0:4::/96
      dynamic-pool 10.208.0.0/12
      data-dir /var/spool/tayga
    '';
    "coredns/zones/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa".source = pkgs.fetchurl {
      url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com/gravity/db.9.6.0.1.4.6.b.c.0.a.2.ip6.arpa";
      sha256 = "sha256-v2SG5+qhlfV81zk1vAOnKy3n7nwk3NQgDGK7NfDUnNk=";
    };
    "coredns/zones/db.gravity".source = pkgs.fetchurl {
      url = "https://artifacts-nichi.s3.us-west-000.backblazeb2.com/gravity/db.gravity";
      sha256 = "sha256-d1JVsiXqwybYBg4p/TEkmvniCSVOUlc+bU3jMv81RjE=";
    };
  };
  systemd.services.divi = {
    serviceConfig = {
      ExecStart = "${pkgs.tayga}/bin/tayga -d --config /etc/rait/tayga.conf";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.bird = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bird2}/bin/bird -d -c /etc/bird.conf";
    };
  };
  systemd.services.gravity = {
    serviceConfig = with pkgs;{
      ExecStartPre = [
        "${iproute2}/bin/ip netns add gravity"
      ];
      ExecStart = "${iproute2}/bin/ip netns exec gravity ${babeld}/bin/babeld -c /etc/rait/babeld.conf";
      ExecStartPost = [
        "${rait}/bin/rait up"
        "${iproute2}/bin/ip link add gravity group 54 type veth peer host netns gravity"
        "${iproute2}/bin/ip link set up gravity"
        "${iproute2}/bin/ip -n gravity link set up host"
        "${iproute2}/bin/ip -n gravity link set up lo"
        "${iproute2}/bin/ip -n gravity addr replace 2a0c:b641:69c:e0d0::1/128 dev lo"
        "${iproute2}/bin/ip -6 ru add fwmark 54 suppress_ifgroup 54 pref 1024"
      ];
      ExecReload = [
        "${rait}/bin/rait sync"
      ];
      ExecStopPost = [
        "${iproute2}/bin/ip netns del gravity"
        "${iproute2}/bin/ip -6 ru del pref 1024"
      ];
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
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
