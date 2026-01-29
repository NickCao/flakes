{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
{

  services.gravity = {
    enable = true;
    reload.enable = true;
    address = [ "2a0c:b641:69c:99cc::1/128" ];
    bird = {
      enable = true;
      routes = [ "route 2a0c:b641:69c:99c0::/60 from ::/0 unreachable" ];
      pattern = "grv*";
    };
    ipsec = {
      enable = true;
      iptfs = true;
      organization = "nickcao";
      commonName = "local";
      port = 13000;
      interfaces = [
        "wlan0"
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

  systemd.services.gravity.enable = false;

  systemd.services.bird.after = [ "network-online.target" ];
  systemd.services.bird.wants = [ "network-online.target" ];

  cloud.services.gost.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.gost)
      "-L"
      "auto://127.0.0.1:1080?interface=gravity"
    ];
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
      { Destination = "2a0c:b641:69c:99cc::3/128"; }
    ];
  };

  systemd.packages = [ pkgs.tayga ];
  systemd.services."tayga@clatd" = {
    overrideStrategy = "asDropin";
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ config.environment.etc."tayga/clatd.conf".source ];
    serviceConfig.ExecStartPre = [
      "${pkgs.iproute2}/bin/ip sr tunsrc set 2a0c:b641:69c:99cc::1"
      "${pkgs.iproute2}/bin/ip r replace 64:ff9b::/96 from 2a0c:b641:69c:99c0::/60 encap seg6 mode encap segs 2a0c:b641:69c:aeb6::3 dev gravity vrf gravity mtu 1280"
      "${pkgs.iproute2}/bin/ip r replace default from 2a0c:b641:69c:99cc::1 dev gravity"
    ];
  };

  environment.etc."tayga/clatd.conf".text = ''
    tun-device clat
    prefix 64:ff9b::/96
    ipv4-addr 192.0.0.1
    map 192.0.0.2 2a0c:b641:69c:99cc::2
    map 192.0.0.3 2a0c:b641:69c:99cc::3
    wkpf-strict no
  '';
}
