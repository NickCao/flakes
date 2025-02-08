{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.services.gravity;
  stateful = config.systemd.network.netdevs.stateful.vrfConfig.Table;
  stateles = config.systemd.network.netdevs.stateles.vrfConfig.Table;
in
{
  options.services.gravity = {
    enable = mkEnableOption "gravity overlay network, next generation";
    ipsec = {
      enable = mkEnableOption "ipsec";
      organization = mkOption { type = types.str; };
      commonName = mkOption { type = types.str; };
      endpoints = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              serialNumber = mkOption { type = types.str; };
              addressFamily = mkOption { type = types.str; };
              address = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
            };
          }
        );
      };
      port = mkOption {
        type = types.port;
        default = 13000;
      };
      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
    reload.enable = mkEnableOption "auto reload registry";
    config = mkOption {
      type = types.nullOr types.path;
      default = null;
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
      enable = mkEnableOption "bird integration";
      exit.enable = mkEnableOption "exit node";
      prefix = mkOption {
        type = types.str;
        description = "prefix to be announced for local node";
      };
      pattern = mkOption {
        type = types.str;
        default = "grv*";
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
        default = "10.200.0.0/16";
        description = "prefix for dynamic assignment";
      };
      oif = mkOption {
        type = types.str;
        description = "name of ipv4 outbound interface";
      };
      allow = mkOption {
        default = [ "2a0c:b641:69c::/48" ];
        type = types.listOf types.str;
        description = "list of addresses allowed to use divi";
      };
    };
    srv6 = {
      enable = mkEnableOption "sample srv6 configuration";
      prefix = mkOption {
        type = types.str;
        description = "prefix for srv6 actions";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ({
      boot.kernelModules = [ "vrf" ];
      boot.kernel.sysctl = {
        "net.vrf.strict_mode" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        # https://www.kernel.org/doc/html/latest/networking/vrf.html#applications
        # established sockets will be created in the VRF based on the ingress interface
        # in case ingress traffic comes from inside the VRF targeting VRF external addresses
        # the connection would silently fail
        "net.ipv4.tcp_l3mdev_accept" = 0;
        "net.ipv4.udp_l3mdev_accept" = 0;
        "net.ipv4.raw_l3mdev_accept" = 0;
      };

      systemd.services.gravity-rules = {
        path = with pkgs; [
          iproute2
          coreutils
        ];
        script = ''
          ip -4 ru del pref 0 || true
          ip -6 ru del pref 0 || true
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

      systemd.network.config.networkConfig = {
        ManageForeignRoutes = false;
      };

      systemd.network.netdevs = {
        gravity = {
          netdevConfig = {
            Kind = "vrf";
            Name = "gravity";
          };
          vrfConfig = {
            Table = cfg.table + 0;
          };
        };
        stateful = {
          netdevConfig = {
            Kind = "vrf";
            Name = "stateful";
          };
          vrfConfig = {
            Table = cfg.table + 1;
          };
        };
        stateles = {
          netdevConfig = {
            Kind = "vrf";
            Name = "stateles";
          };
          vrfConfig = {
            Table = cfg.table + 2;
          };
        };
      };

      systemd.network.networks = {
        gravity = {
          name = config.systemd.network.netdevs.gravity.netdevConfig.Name;
          address = cfg.address;
          linkConfig.RequiredForOnline = false;
          routingPolicyRules =
            lib.optionals (cfg.srv6.enable) [
              {
                Priority = 500;
                Family = "ipv6";
                Table = 100; # localsid
                From = "2a0c:b641:69c::/48";
                To = "${cfg.srv6.prefix}6::/64";
              }
            ]
            ++ [
              {
                Priority = 2000;
                Family = "both";
                L3MasterDevice = true;
                Type = "unreachable";
              }
              {
                Priority = 3000;
                Family = "both";
                Table = "local";
              }
            ];
        };
        stateful = {
          name = config.systemd.network.netdevs.stateful.netdevConfig.Name;
          linkConfig.RequiredForOnline = false;
        };
        stateles = {
          name = config.systemd.network.netdevs.stateles.netdevConfig.Name;
          linkConfig.RequiredForOnline = false;
        };
      };
    })
    (mkIf (cfg.config != null) {
      systemd.services.gravity = {
        path = with pkgs; [ ranet ];
        script = "ranet -c ${cfg.config} up";
        reload = "ranet -c ${cfg.config} up";
        preStop = "ranet -c ${cfg.config} down";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        unitConfig = {
          AssertFileNotEmpty = "/var/lib/gravity/combined.json";
        };
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
      environment.systemPackages = [ pkgs.wireguard-tools ];
    })
    (mkIf cfg.bird.enable {
      services.bird = {
        enable = true;
        package = pkgs.bird-babel-rtt;
        config = ''
          ipv6 sadr table sadr6;
          protocol device {
            scan time 5;
          }
          ${optionalString cfg.bird.exit.enable ''
            ipv6 table stateles;
            ipv6 table stateful;

            protocol pipe stateles_pipe {
              table stateles;
              peer table master6;
              import all;
              export none;
            }

            protocol pipe stateful_pipe {
              table stateful;
              peer table master6;
              import all;
              export none;
            }

            protocol kernel stateles_kern {
              kernel table ${toString stateles};
              ipv6 {
                table stateles;
                import none;
                export all;
              };
            }

            protocol kernel stateful_kern {
              kernel table ${toString stateful};
              ipv6 {
                table stateful;
                import none;
                export all;
              };
            }

          ''}
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
            ${optionalString cfg.bird.exit.enable ''
              route 2a0c:b641:69c::/48 from ::/0 unreachable;
              route ::/0 from 2a0c:b641:69c::/48 via "stateles";
            ''}
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
              link quality etx;
              rxcost 32;
              hello interval 20 s;
              rtt cost 1024;
              rtt max 1024 ms;
              rx buffer 2000;
            };
            interface "gn*" {
              type tunnel;
              link quality etx;
              rxcost 32;
              hello interval 20 s;
              rtt cost 1024;
              rtt max 1024 ms;
              rx buffer 2000;
            };
          }

          ${optionalString cfg.bird.exit.enable ''
            protocol static announce4 {
              ipv4;
              route 44.32.148.0/24 unreachable;
            }
            protocol static announce6 {
              ipv6;
              route 2a0c:b641:69c::/48 via "gravity";
              route 2a0c:b641:690::/44 unreachable;
              route 2602:feda:bc0::/44 unreachable;
            }
            protocol kernel kernel4 {
              ipv4 {
                export where proto = "announce4";
                import all;
              };
              learn;
            }
            protocol kernel kernel6 {
              ipv6 {
                export where proto = "announce6";
                import all;
              };
              learn;
            }
            include "${config.sops.secrets.bgp_passwd.path}";
            protocol bgp vultr4 {
              ipv4 {
                import none;
                export where proto = "announce4";
              };
              local as 209297;
              graceful restart on;
              multihop 2;
              neighbor 169.254.169.254 as 64515;
              password BGP_PASSWD;
            }
            protocol bgp vultr6 {
              ipv6 {
                import none;
                export where proto = "announce6";
              };
              local as 209297;
              graceful restart on;
              multihop 2;
              neighbor 2001:19f0:ffff::1 as 64515;
              password BGP_PASSWD;
            }
          ''}
        '';
      };
    })
    (mkIf cfg.bird.exit.enable {
      sops.secrets.bgp_passwd = {
        sopsFile = ./secrets.yaml;
        owner = config.systemd.services.bird.serviceConfig.User;
        reloadUnits = [ config.systemd.services.bird.name ];
      };
      services.bird.checkConfig = false;
      systemd.network.netdevs.amprnet.netdevConfig = {
        Kind = "dummy";
        Name = "amprnet";
      };
      systemd.network.networks.amprnet = {
        name = "amprnet";
        address = [ "44.32.148.1/32" ];
      };
    })
    (mkIf cfg.divi.enable {
      systemd.network.networks.nat64 = {
        name = "nat64";
        routes = [
          {
            Destination = "64:ff9b::/96";
            Table = stateful;
          }
          { Destination = "10.201.0.0/16"; }
        ];
        networkConfig.LinkLocalAddressing = false;
        linkConfig.RequiredForOnline = false;
      };

      systemd.network.networks.divi = {
        name = "divi";
        linkConfig = {
          MTUBytes = "1400";
        };
        routes = [
          {
            Destination = cfg.divi.prefix;
            Table = cfg.table;
          }
          { Destination = cfg.divi.dynamic-pool; }
        ];
        networkConfig.LinkLocalAddressing = false;
        linkConfig.RequiredForOnline = false;
      };

      systemd.services.nat64 = {
        serviceConfig = {
          ExecStart = "${pkgs.tayga}/bin/tayga -d --config ${pkgs.writeText "tayga.conf" ''
            tun-device nat64
            ipv4-addr 10.201.0.1
            ipv6-addr fc00::
            prefix 64:ff9b::/96
            dynamic-pool 10.201.0.0/16
          ''}";
        };
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      systemd.services.divi = {
        serviceConfig = {
          ExecStart = "${pkgs.tayga}/bin/tayga -d --config ${pkgs.writeText "tayga.conf" ''
            tun-device divi
            ipv4-addr 10.200.0.1
            prefix ${cfg.divi.prefix}
            dynamic-pool ${cfg.divi.dynamic-pool}
          ''}";
        };
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      networking.nftables = {
        enable = true;
        tables = {
          filter4 = {
            name = "filter";
            family = "inet";
            content = ''
              chain forward {
                type filter hook forward priority 0;
                tcp flags syn tcp option maxseg size set 1200
              }
            '';
          };
          filter6 = {
            name = "filter";
            family = "ip6";
            content = ''
              chain postrouting {
                type nat hook postrouting priority 100;
                iifname "stateful" oifname "${cfg.divi.oif}" masquerade
              }
              chain forward {
                type filter hook forward priority 0;
                oifname "divi" ip6 saddr != { ${lib.concatStringsSep ", " cfg.divi.allow} } reject
              }
            '';
          };
          nat = {
            family = "ip";
            content = ''
              chain postrouting {
                type nat hook postrouting priority 100;
                oifname "${cfg.divi.oif}" masquerade
              }
            '';
          };
        };
      };
    })
    (mkIf cfg.reload.enable {
      sops.secrets.gravity_registry.sopsFile = ./secrets.yaml;
      systemd.tmpfiles.rules = [ "d /var/lib/gravity 0755 root root - -" ];
      systemd.services.gravity-registry = {
        path = with pkgs; [
          curl
          jq
          coreutils
        ];
        script = ''
          set -euo pipefail
          for filename in registry.json combined.json
          do
            curl --fail --retry 3 --retry-connrefused \
              -H @${config.sops.secrets.gravity_registry.path} \
              https://raw.githubusercontent.com/tuna/gravity/artifacts/artifacts/$filename --output /var/lib/gravity/$filename.new
            mv /var/lib/gravity/$filename.new /var/lib/gravity/$filename
          done
          /run/current-system/systemd/bin/systemctl reload-or-restart --no-block gravity || true
          /run/current-system/systemd/bin/systemctl reload-or-restart --no-block gravity-ipsec || true
        '';
        serviceConfig.Type = "oneshot";
      };
      systemd.timers.gravity-registry = {
        timerConfig = {
          OnCalendar = "*:0/15";
        };
        wantedBy = [ "timers.target" ];
      };
    })
    (mkIf cfg.srv6.enable {
      environment.etc."iproute2/rt_tables.d/gravity.conf" = {
        mode = "0644";
        text = ''
          100 localsid
          ${toString stateles} stateles
          ${toString stateful} stateful
        '';
      };
      systemd.services.gravity-srv6 = {
        path = with pkgs; [ iproute2 ];
        serviceConfig =
          let
            routes = [
              "blackhole default table localsid"
              "${cfg.srv6.prefix}6::1 encap seg6local action End.DT6 vrftable stateles dev gravity table localsid"
              "${cfg.srv6.prefix}6::2 encap seg6local action End                       dev gravity table localsid"
              "${cfg.srv6.prefix}6::3 encap seg6local action End.DT6 vrftable stateful dev gravity table localsid"
            ];
          in
          {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 r a ${route}") routes;
            ExecStop = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 r d ${route}") routes;
          };
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    })
    (mkIf cfg.ipsec.enable {
      sops.secrets.ipsec.sopsFile = ./secrets.yaml;
      environment.systemPackages = [ config.services.strongswan-swanctl.package ];
      environment.etc."ranet/config.json".source = (pkgs.formats.json { }).generate "config.json" {
        organization = cfg.ipsec.organization;
        common_name = cfg.ipsec.commonName;
        endpoints = builtins.map (ep: {
          serial_number = ep.serialNumber;
          address_family = ep.addressFamily;
          address = ep.address;
          port = cfg.ipsec.port;
          updown = pkgs.writeShellScript "updown" ''
            LINK=gn$(printf '%08x\n' "$PLUTO_IF_ID_OUT")
            case "$PLUTO_VERB" in
              up-client)
                ip link add "$LINK" type xfrm if_id "$PLUTO_IF_ID_OUT"
                ip link set "$LINK" master gravity multicast on mtu 1400 up
                ;;
              down-client)
                ip link del "$LINK"
                ;;
            esac
          '';
        }) cfg.ipsec.endpoints;
      };
      systemd.services.gravity-ipsec =
        let
          command = "ranet -c /etc/ranet/config.json -r /var/lib/gravity/registry.json -k ${config.sops.secrets.ipsec.path}";
        in
        {
          path = [
            inputs.ranet-ipsec.packages.x86_64-linux.default
            pkgs.iproute2
          ];
          script = "${command} up";
          reload = "${command} up";
          preStop = "${command} down";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          unitConfig = {
            AssertFileNotEmpty = "/var/lib/gravity/registry.json";
          };
          bindsTo = [ "strongswan-swanctl.service" ];
          wants = [
            "network-online.target"
            "strongswan-swanctl.service"
          ];
          after = [
            "network-online.target"
            "strongswan-swanctl.service"
          ];
          wantedBy = [ "multi-user.target" ];
          reloadTriggers = [ config.environment.etc."ranet/config.json".source ];
        };
      services.strongswan-swanctl = {
        enable = true;
        package = pkgs.strongswan_6;
        strongswan.extraConfig = ''
          charon {
            ikesa_table_size = 32
            ikesa_table_segments = 4
            reuse_ikesa = no
            interfaces_use = ${lib.strings.concatStringsSep "," cfg.ipsec.interfaces}
            port = 0
            port_nat_t = ${toString cfg.ipsec.port}
            retransmit_timeout = 30
            retransmit_base = 1
            plugins {
              socket-default {
                set_source = yes
                set_sourceif = yes
              }
              dhcp {
                load = no
              }
            }
          }
          charon-systemd {
            journal {
              default = -1
            }
          }
        '';
      };
    })
  ]);
}
