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

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.tcp_l3mdev_accept" = 0;
    "net.ipv4.udp_l3mdev_accept" = 0;
    "net.ipv4.raw_l3mdev_accept" = 0;
  };

  systemd.services.gravity = {
    serviceConfig = with pkgs;{
      ExecStart = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} up";
      ExecReload = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} up";
      ExecStop = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} down";
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.network.enable = true;
  systemd.network.netdevs = {
    gravity = {
      netdevConfig = {
        Name = "gravity";
        Kind = "vrf";
      };
      vrfConfig = {
        Table = 200;
      };
    };
    gravity-dummy = {
      netdevConfig = {
        Name = "gravity-dummy";
        Kind = "dummy";
      };
    };
  };
  systemd.network.networks = {
    gravity = {
      name = "gravity";
      routes = [
        {
          routeConfig = {
            Destination = "2a0c:b641:69c::/48";
          };
        }
      ];
    };
    gravity-dummy = {
      name = "gravity-dummy";
      vrf = [ "gravity" ];
      addresses = [{ addressConfig.Address = "2a0c:b641:69c:4ed0::1/60"; }];
    };
    divi = {
      name = "divi";
      routes = [
        { routeConfig = { Destination = nat64-prefix; Table = 200; }; }
        { routeConfig.Destination = nat64-prefix; }
        { routeConfig.Destination = dynamic-pool; }
      ];
    };
  };

  systemd.services.fix-ip-rules = {
    path = with pkgs;[ iproute2 coreutils ];
    script = ''
      ip -4 ru del pref 0 || true
      ip -6 ru del pref 0 || true
      if [ -z "$(ip -4 ru list pref 2000)" ]; then
        ip -4 ru add pref 2000 l3mdev unreachable proto kernel
      fi
      if [ -z "$(ip -6 ru list pref 2000)" ]; then
        ip -6 ru add pref 2000 l3mdev unreachable proto kernel
      fi
      if [ -z "$(ip -4 ru list pref 3000)" ]; then
        ip -4 ru add pref 3000 lookup local proto kernel
      fi
      if [ -z "$(ip -6 ru list pref 3000)" ]; then
        ip -6 ru add pref 3000 lookup local proto kernel
      fi
    '';
    serviceConfig.RemainAfterExit = true;
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  services.bird2 = {
    enable = true;
    checkConfig = false;
    config = ''
      include "${config.sops.secrets.bgp_passwd.path}";
      ipv6 sadr table sadr6;
      protocol device {
        scan time 5;
      }
      protocol direct {
        ipv6 sadr;
        interface "gravity-dummy";
      }
      protocol kernel {
        kernel table 200;
        ipv6 sadr {
          export all;
          import none;
        };
      }
      protocol babel gravity {
        vrf "gravity";
        ipv6 sadr {
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
      protocol bgp vultr {
        ipv6 {
          import none;
          export none;
        };
        local as 209297;
        graceful restart on;
        multihop 2;
        neighbor 2001:19f0:ffff::1 as 64515;
        password BGP_PASSWD;
      }
    '';
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
