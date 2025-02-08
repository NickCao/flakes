{ pkgs, ... }:
{

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:99cc::1/128" ];
    bird = {
      enable = true;
      prefix = "2a0c:b641:69c:99c0::/60";
      pattern = "grv*";
    };
    ipsec = {
      enable = true;
      organization = "nickcao";
      commonName = "local";
      port = 13000;
      interfaces = [ "wlan0" ];
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

  systemd.services.gravity.enable = false;

  systemd.services.bird.after = [ "network-online.target" ];
  systemd.services.bird.wants = [ "network-online.target" ];

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
      };
      dns = {
        servers = [
          {
            tag = "cloudflare";
            address = "https://[2606:4700:4700::1111]/dns-query";
            strategy = "prefer_ipv6";
          }
          {
            tag = "local";
            address = "local";
            strategy = "prefer_ipv4";
          }
        ];
        final = "cloudflare";
      };
      inbounds = [
        {
          type = "mixed";
          tag = "inbound";
          listen = "127.0.0.1";
          listen_port = 1080;
          sniff = true;
          sniff_override_destination = true;
        }
      ];
      outbounds = [
        {
          type = "direct";
          tag = "gravity";
          bind_interface = "gravity";
          inet6_bind_address = "2a0c:b641:69c:99cc::1";
          domain_strategy = "prefer_ipv6";
        }
        {
          type = "direct";
          tag = "direct";
        }
      ];
      route = {
        final = "gravity";
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
    addresses = [ { Address = "192.0.0.2/32"; } ];
    routes = [
      { Destination = "0.0.0.0/0"; }
      { Destination = "2a0c:b641:69c:99cc::2/128"; }
    ];
  };

  systemd.services.clatd = {
    path = with pkgs; [
      iproute2
      tayga
    ];
    script = ''
      ip sr tunsrc set 2a0c:b641:69c:99cc::1
      ip r replace 64:ff9b::/96 from 2a0c:b641:69c:99c0::/60 \
        encap seg6 mode encap segs 2a0c:b641:69c:aeb6::3 dev gravity vrf gravity mtu 1280
      ip r replace default from 2a0c:b641:69c:99cc::1 dev gravity
      exec tayga -d --config ${pkgs.writeText "tayga.conf" ''
        tun-device clat
        prefix 64:ff9b::/96
        ipv4-addr 192.0.0.1
        map 192.0.0.2 2a0c:b641:69c:99cc::2
      ''}
    '';
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
