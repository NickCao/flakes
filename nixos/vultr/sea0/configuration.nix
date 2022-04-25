{ config, pkgs, ... }:
let
  dynamic-pool = "10.208.0.0/12";
  nat64-prefix = "2a0c:b641:69c:4ed4:0:4::/96";
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
    secrets.bgp_passwd = {
      sopsFile = ../../../modules/bgp/secrets.yaml;
      owner = "bird2";
      reloadUnits = [ "bird2.service" ];
    };
  };

  services.gravity-ng = {
    enable = true;
    config = config.sops.secrets.ranet.path;
    address = [ "2a0c:b641:69c:4ed0::1/128" ];
  };

  services.bird2 = {
    enable = true;
    checkConfig = false;
    config = ''
      include "${config.sops.secrets.bgp_passwd.path}";
      ipv6 sadr table gravity_table;
      protocol device {
        scan time 5;
      }
      protocol kernel {
        kernel table 200;
        ipv6 sadr {
          table gravity_table;
          export all;
          import none;
        };
      }
      protocol kernel {
        ipv6 {
          export all;
          import all;
        };
        learn;
      }
      protocol babel gravity {
        vrf "gravity";
        ipv6 sadr {
          table gravity_table;
          export all;
          import all;
        };
        randomize router id;
        interface "grv*" {
          type tunnel;
          rxcost 32;
          hello interval 20 s;
          rtt cost 1024;
          rtt max 1024 ms;
        };
      }
      protocol static gravity_announce {
        ipv6 sadr {
          table gravity_table;
        };
        route 2a0c:b641:69c:4ed0::/60 from ::/0 unreachable;
        route 2a0c:b641:69c::/48 from ::/0 unreachable;
        route ::/0 from 2a0c:b641:69c:99cc::/64 recursive 2606:4700:4700::1111;
        igp table master6;
      }
      protocol static global_announce {
        ipv6;
        route 2a0c:b641:69c::/48 via "gravity";
      }
      protocol bgp vultr {
        ipv6 {
          import none;
          export where (proto = "global_announce");
        };
        local as 209297;
        graceful restart on;
        multihop 2;
        neighbor 2001:19f0:ffff::1 as 64515;
        password BGP_PASSWD;
      }
    '';
  };

  systemd.network.networks.divi = {
    name = "divi";
    routes = [
      { routeConfig = { Destination = nat64-prefix; Table = config.services.gravity-ng.table; }; }
      { routeConfig.Destination = nat64-prefix; }
      { routeConfig.Destination = dynamic-pool; }
    ];
  };

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain forward {
          type filter hook forward priority 0;
          tcp flags syn tcp option maxseg size set 1300
        }
      }
      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100;
          oifname "enp1s0" masquerade
        }
      }
      table ip6 filter {
        chain forward {
          type filter hook forward priority 0;
          oifname "divi" ip6 saddr != { 2a0c:b641:69c::/48, 2001:470:4c22::/48 } reject
        }
      }
    '';
  };

  systemd.services.divi = {
    serviceConfig = {
      ExecStart = "${pkgs.tayga}/bin/tayga -d --config ${pkgs.writeText "tayga.conf" ''
          tun-device divi
          ipv4-addr 10.208.0.1
          prefix ${nat64-prefix}
          dynamic-pool ${dynamic-pool}
        ''}";
    };
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
