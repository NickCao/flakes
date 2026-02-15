{ lib, ... }:
{
  systemd.services.bird.after = [ "network-online.target" ];
  systemd.services.bird.wants = [ "network-online.target" ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:a230::1/128" ];
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
      routes = lib.singleton {
        Destination = "::/0";
        Source = "2a0c:b641:69c:a231::/64";
      };
    };
  };
}
