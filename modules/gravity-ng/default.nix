{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.gravity-ng;
in
{
  options.services.gravity-ng = {
    enable = mkEnableOption "gravity overlay network, next generation";
    config = mkOption {
      type = types.path;
      description = "path to ranet config";
    };
    table = mkOption {
      type = types.int;
      default = 200;
      description = "routing table number for the vrf interface";
    };
    address = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = "list of addresses to be added to the vrf interface";
    };
    bird = {
      leaf.enable = mkEnableOption "leaf node bird configuration";
      spine.enable = mkEnableOption "spine node bird configuration";
      prefix = mkOption {
        type = types.str;
        description = "prefix to be announced for local node";
      };
      pattern = mkOption {
        type = types.str;
        description = "pattern for wireguard interfaces";
      };
    };
    divi = {
      enable = mkEnableOption "sample divi configuration";
      prefix = mkOption {
        type = types.str;
        description = "prefix to be announced for nat64";
      };
      dynamic-pool = mkOption {
        type = types.str;
        default = "10.208.0.0/12";
        description = "prefix for dynamic assignment";
      };
      oif = mkOption {
        type = types.str;
        description = "name of ipv4 outbound interface";
      };
      allow = mkOption {
        default = [ ];
        type = types.listOf types.str;
        description = "list of addresses allowed to use divi";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      boot.kernel.sysctl = {
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        # https://www.kernel.org/doc/html/latest/networking/vrf.html#applications
        "net.ipv4.tcp_l3mdev_accept" = 1;
        "net.ipv4.udp_l3mdev_accept" = 0;
        "net.ipv4.raw_l3mdev_accept" = 0;
      };

      systemd.services.gravity = {
        path = with pkgs; [ ranet ];
        script = "ranet -c ${cfg.config} up";
        reload = "ranet -c ${cfg.config} up";
        preStop = "ranet -c ${cfg.config} down";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.gravity-rules = {
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
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        after = [ "network-pre.target" ];
        before = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      systemd.network.enable = true;
      systemd.network.netdevs.gravity = {
        netdevConfig = {
          Name = "gravity";
          Kind = "vrf";
        };
        vrfConfig = {
          Table = cfg.table;
        };
      };
      systemd.network.networks.gravity = {
        name = "gravity";
        address = cfg.address;
      };
    })
    (mkIf cfg.bird.leaf.enable {
      services.bird2 = {
        enable = true;
        config = ''
          ipv6 sadr table sadr6;

          protocol device {
            scan time 5;
          }

          protocol kernel {
            kernel table ${toString cfg.table};
            ipv6 sadr {
              export all;
              import none;
            };
          }

          protocol static {
            ipv6 sadr;
            route ${cfg.bird.prefix} from ::/0 unreachable;
          }

          protocol babel {
            vrf "gravity";
            ipv6 sadr {
              export all;
              import all;
            };
            randomize router id;
            interface "${cfg.bird.pattern}" {
              type tunnel;
              rxcost 32;
              hello interval 20 s;
              rtt cost 1024;
              rtt max 1024 ms;
            };
          }
        '';
      };
    })
    (mkIf cfg.bird.spine.enable {
      sops.secrets.bgp_passwd = {
        sopsFile = ../bgp/secrets.yaml;
        owner = "bird2";
        reloadUnits = [ "bird2.service" ];
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

          protocol kernel {
            kernel table ${toString cfg.table};
            ipv6 sadr {
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

          protocol static {
            ipv6 sadr;
            route ${cfg.bird.prefix} from ::/0 unreachable;
            route 2a0c:b641:69c::/48 from ::/0 unreachable;
            route ::/0 from 2a0c:b641:69c::/48 recursive 2606:4700:4700::1111;
            igp table master6;
          }

          protocol babel {
            vrf "gravity";
            ipv6 sadr {
              export all;
              import all;
            };
            randomize router id;
            interface "${cfg.bird.pattern}" {
              type tunnel;
              rxcost 32;
              hello interval 20 s;
              rtt cost 1024;
              rtt max 1024 ms;
            };
          }

          protocol static announce {
            ipv6;
            route 2a0c:b641:69c::/48 via "gravity";
          }

          protocol bgp vultr {
            ipv6 {
              import none;
              export where proto = "announce";
            };
            local as 209297;
            graceful restart on;
            multihop 2;
            neighbor 2001:19f0:ffff::1 as 64515;
            password BGP_PASSWD;
          }
        '';
      };
    })
    (mkIf cfg.divi.enable {
      systemd.network.networks.divi = {
        name = "divi";
        routes = [
          { routeConfig = { Destination = cfg.divi.prefix; Table = cfg.table; }; }
          { routeConfig.Destination = cfg.divi.prefix; }
          { routeConfig.Destination = cfg.divi.dynamic-pool; }
        ];
      };
      systemd.services.divi = {
        serviceConfig = {
          ExecStart = "${pkgs.tayga}/bin/tayga -d --config ${pkgs.writeText "tayga.conf" ''
          tun-device divi
          ipv4-addr 10.208.0.1
          prefix ${cfg.divi.prefix}
          dynamic-pool ${cfg.divi.dynamic-pool}
        ''}";
        };
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
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
              oifname "${cfg.divi.oif}" masquerade
            }
          }
          table ip6 filter {
            chain forward {
              type filter hook forward priority 0;
              oifname "divi" ip6 saddr != { ${lib.concatStringsSep ", " cfg.divi.allow} } reject
            }
          }
        '';
      };
    })
  ]);
}
