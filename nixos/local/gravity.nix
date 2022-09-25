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

  cloud.services.gravity-proxy.config = {
    ExecStart = "${pkgs.ranet}/bin/ranet-proxy --listen 127.0.0.1:9999 --bind 2a0c:b641:69c:99cc::1 --interface gravity --prefix 2a0c:b641:69c:7864:0:4::";
  };

  services.v2ray = {
    enable = true;
    config = {
      log = { loglevel = "error"; access = "none"; };
      dns = {
        servers = [
          { address = "https://1.0.0.1/dns-query"; }
          { address = "https://1.1.1.1/dns-query"; }
        ];
      };
      inbounds = [
        {
          listen = "127.0.0.1";
          port = 8888;
          protocol = "http";
          sniffing = { destOverride = [ "http" "tls" ]; enabled = true; metadataOnly = false; };
          tag = "http";
        }
        {
          listen = "127.0.0.1";
          port = 1080;
          protocol = "socks";
          sniffing = { destOverride = [ "http" "tls" ]; enabled = true; metadataOnly = false; };
          tag = "socks";
        }
      ];
      outbounds = [
        {
          protocol = "blackhole";
          tag = "blackhole";
        }
        {
          protocol = "freedom";
          tag = "direct";
        }
        {
          protocol = "freedom";
          settings = {
            domainStrategy = "UseIP";
          };
          proxySettings = {
            tag = "gravity";
          };
          tag = "proxy";
        }
        {
          protocol = "socks";
          settings = {
            servers = [{
              address = "127.0.0.1";
              port = 9999;
            }];
            version = "5";
          };
          tag = "gravity";
        }
      ];
      routing = {
        domainMatcher = "mph";
        domainStrategy = "IPIfNonMatch";
        rules = [
          { domains = [ "geosite:cn" ]; outboundTag = "direct"; type = "field"; }
          { ip = [ "geoip:private" "geoip:cn" ]; outboundTag = "direct"; type = "field"; }
          { network = "tcp"; outboundTag = "proxy"; type = "field"; }
          { network = "udp"; outboundTag = "direct"; type = "field"; }
        ];
      };
    };
  };

  systemd.network.networks.clat = {
    name = "clat";
    vrf = [ "gravity" ];
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
