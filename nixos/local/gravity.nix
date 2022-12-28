{ config, pkgs, ... }:
{
  sops.secrets.ranet.reloadUnits = [ "gravity.service" ];

  services.gravity = {
    enable = true;
    reload.enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:99cc::1/128" ];
    bird = {
      enable = true;
      prefix = "2a0c:b641:69c:99cc::/64";
      pattern = "grv*";
    };
  };
  systemd.services.bird2.after = [ "network-online.target" ];

  systemd.services.sing-box =
    let
      config = {
        dns = {
          servers = [{
            tag = "cloudflare";
            address = "https://1.0.0.1/dns-query";
          }];
          strategy = "prefer_ipv6";
        };
        inbounds = [{
          type = "mixed";
          tag = "inbound";
          listen = "127.0.0.1";
          listen_port = 1080;
          sniff = true;
          sniff_override_destination = true;
          domain_strategy = "prefer_ipv6";
        }];
        outbounds = [
          {
            type = "direct";
            tag = "gravity";
            bind_interface = "gravity";
            inet6_bind_address = "2a0c:b641:69c:99cc::1";
          }
          {
            type = "direct";
            tag = "direct";
          }
        ];
        route = {
          rules = [{
            geosite = [ "cn" ];
            geoip = [ "cn" ];
            outbound = "direct";
          }];
          final = "gravity";
        };
      };
    in
    {
      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "sing-box";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${(pkgs.formats.json {}).generate "config.json" config} -D $STATE_DIRECTORY";
      };
      wantedBy = [ "multi-user.target" ];
    };

  systemd.network.networks.clat = {
    name = "clat";
    vrf = [ "gravity" ];
    linkConfig = {
      MTUBytes = "1400";
    };
    addresses = [
      { addressConfig.Address = "192.0.0.2/32"; }
    ];
    routes = [
      { routeConfig.Destination = "0.0.0.0/0"; }
      { routeConfig.Destination = "2a0c:b641:69c:99cc::2/128"; }
    ];
  };

  systemd.services.clatd = {
    path = with pkgs; [ tayga ];
    script = "tayga -d --config ${pkgs.writeText "tayga.conf" ''
      tun-device clat
      prefix 2a0c:b641:69c:7864:0:4::/96
      ipv4-addr 192.0.0.1
      map 192.0.0.2 2a0c:b641:69c:99cc::2
    ''}";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
