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
    divi = {
      enable = true;
      prefix = "2a0c:b641:69c:4ed4:0:4::/96";
      oif = "enp1s0";
      allow = [ "2a0c:b641:69c::/48" ];
    };
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
        kernel table ${toString config.services.gravity-ng.table};
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
}
