{
  lib,
  pkgs,
  ...
}:
{
  boot.kernel.sysctl."net.ipv4.tcp_l3mdev_accept" = 1;

  systemd.services.bird.after = [ "network-online.target" ];
  systemd.services.bird.wants = [ "network-online.target" ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:a230::1/127" ];
    bird = {
      enable = true;
      routes = [
        "route 2a0c:b641:69c:a230::/60 from ::/0 unreachable"
        "route 2a0c:b641:69c:a231::/64 from ::/0 via \"svc\""
      ];
      pattern = "grv*";
    };
    ipsec = {
      enable = true;
      iptfs = true;
      organization = "nickcao";
      commonName = "subframe";
      port = 13000;
      interfaces = [
        "eth0"
      ];
      endpoints = [
        {
          serialNumber = "0";
          addressFamily = "ip4";
        }
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
    };
  };

  systemd.network.netdevs = {
    "10-svc" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "svc";
      };
    };
  };

  systemd.network.networks = {
    "10-svc" = {
      name = "svc";
      networkConfig.IPv6SendRA = true;
      ipv6Prefixes = lib.singleton {
        Prefix = "2a0c:b641:69c:a231::/64";
      };
    };
    gravity = {
      addresses = lib.singleton { Address = "44.32.148.19/32"; };
      routes = lib.singleton {
        Destination = "::/0";
        Source = "2a0c:b641:69c:a230::/60";
      };
      routingPolicyRules = lib.singleton {
        Priority = 500;
        Family = "ipv6";
        Table = 100; # localsid
        From = "2a0c:b641:69c::/48";
        To = "2a0c:b641:69c:a236::/64";
      };
    };
  };

  systemd.services.gravity-srv6 = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${pkgs.iproute2}/bin/ip -6 r add blackhole default table 100"
        "${pkgs.iproute2}/bin/ip -6 r add 2a0c:b641:69c:a236::1 encap seg6local action End.DT4 vrftable 200 dev gravity table 100"
        "${pkgs.iproute2}/bin/ip sr tunsrc set 2a0c:b641:69c:a230::1"
        "${pkgs.iproute2}/bin/ip r add default encap seg6 mode encap.red segs 2a0c:b641:69c:aeb6::1 mtu 1400 dev gravity vrf gravity"
      ];
      ExecStop = [
        "${pkgs.iproute2}/bin/ip -6 r del blackhole default table 100"
        "${pkgs.iproute2}/bin/ip -6 r del 2a0c:b641:69c:a236::1 encap seg6local action End.DT4 vrftable 200 dev gravity table 100"
        "${pkgs.iproute2}/bin/ip sr tunsrc set ::"
        "${pkgs.iproute2}/bin/ip r del default encap seg6 mode encap.red segs 2a0c:b641:69c:aeb6::1 mtu 1400 dev gravity vrf gravity"
      ];
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  cloud.caddy.enable = true;
  services.metrics.enable = true;
}
