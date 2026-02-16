{
  config,
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
      routes = lib.singleton {
        Destination = "::/0";
        Source = "2a0c:b641:69c:a231::/64";
      };
    };
  };

  systemd.network.networks.clat = {
    name = "clat";
    vrf = [ "gravity" ];
    linkConfig = {
      MTUBytes = "1400";
      RequiredForOnline = false;
    };
    addresses = [ { Address = "44.32.148.19/32"; } ];
    routes = [
      { Destination = "0.0.0.0/0"; }
      { Destination = "2a0c:b641:69c:a230::64/128"; }
    ];
  };

  systemd.packages = [ pkgs.tayga ];
  systemd.services."tayga@clatd" = {
    overrideStrategy = "asDropin";
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ config.environment.etc."tayga/clatd.conf".source ];
  };

  environment.etc."tayga/clatd.conf".text = ''
    tun-device clat
    prefix 64:ff9b::/96
    ipv4-addr 192.0.0.1
    map 44.32.148.19 2a0c:b641:69c:a230::64
    wkpf-strict no
  '';

  cloud.caddy.enable = true;
  services.metrics.enable = true;
}
