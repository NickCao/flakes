{
  config,
  pkgs,
  lib,
  inputs,
  utils,
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
      iptfs = mkEnableOption "iptfs";
    };
    reload.enable = mkEnableOption "auto reload registry";
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
      routes = mkOption {
        type = types.listOf types.str;
        description = "routes to be announced for local node";
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
      tunsrc = mkOption {
        type = types.str;
        description = "tunsrc for srv6";
      };
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
        "net.ipv4.conf.default.rp_filter" = 0;
        "net.ipv6.conf.*.forwarding" = 1;
        "net.ipv4.conf.*.forwarding" = 1;
        "net.ipv4.conf.*.rp_filter" = 0;
        # https://www.kernel.org/doc/html/latest/networking/vrf.html#applications
        # established sockets will be created in the VRF based on the ingress interface
        # in case ingress traffic comes from inside the VRF targeting VRF external addresses
        # the connection would silently fail
        "net.ipv4.tcp_l3mdev_accept" = lib.mkDefault 0;
        "net.ipv4.udp_l3mdev_accept" = lib.mkDefault 0;
        "net.ipv4.raw_l3mdev_accept" = lib.mkDefault 0;
        "net.ipv4.icmp_errors_extension_mask" = lib.fromHexString "0x01";
        "net.ipv6.icmp.errors_extension_mask" = lib.fromHexString "0x01";
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
            ipv4 table stateles4;
            ipv6 table stateles6;
            ipv6 table stateful;

            protocol pipe stateles4_pipe {
              table stateles4;
              peer table master4;
              import all;
              export none;
            }

            protocol pipe stateles6_pipe {
              table stateles6;
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

            protocol kernel stateles4_kern {
              kernel table ${toString stateles};
              ipv4 {
                table stateles4;
                import none;
                export all;
              };
            }

            protocol kernel stateles6_kern {
              kernel table ${toString stateles};
              ipv6 {
                table stateles6;
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
            ${lib.concatMapStrings (route: ''
              ${route};
            '') cfg.bird.routes}
            ${optionalString cfg.bird.exit.enable ''
              route 2a0c:b641:69c::/48 from ::/0 unreachable;
              route ::/0 from 2a0c:b641:69c::/48 via "stateles";
            ''}
            ${optionalString cfg.divi.enable ''
              route 64:ff9b::/96 from 2a0c:b641:69c::/48 via "stateles";
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
              route 44.32.148.0/24 via "nat64";
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
              authentication md5;
              password BGP_PASSWD;
              allow as sets on;
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
              authentication md5;
              password BGP_PASSWD;
              allow as sets on;
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
      users.users.nat64 = {
        isSystemUser = true;
        group = config.users.groups.nat64.name;
      };
      users.groups.nat64 = { };
      users.users.divi = {
        isSystemUser = true;
        group = config.users.groups.divi.name;
      };
      users.groups.divi = { };
      systemd.network.netdevs.nat64 = {
        netdevConfig = {
          Name = "nat64";
          Kind = "tun";
        };
        tunConfig = {
          User = config.users.users.nat64.name;
        };
      };
      systemd.network.networks.nat64 = {
        name = "nat64";
        linkConfig = {
          RequiredForOnline = false;
          MTUBytes = "1300";
        };
        routes = [
          {
            Destination = "64:ff9b::/96";
            Table = stateful;
          }
          {
            Destination = "64:ff9b::/96";
            Table = stateles;
          }
          { Destination = "10.201.0.0/16"; }
        ];
        networkConfig.LinkLocalAddressing = false;
      };
      systemd.network.netdevs.divi = {
        netdevConfig = {
          Name = "divi";
          Kind = "tun";
        };
        tunConfig = {
          User = config.users.users.divi.name;
        };
      };
      systemd.network.networks.divi = {
        name = "divi";
        linkConfig = {
          RequiredForOnline = false;
          MTUBytes = "1300";
        };
        routes = [
          {
            Destination = cfg.divi.prefix;
            Table = cfg.table;
          }
          { Destination = cfg.divi.dynamic-pool; }
        ];
        networkConfig.LinkLocalAddressing = false;
      };

      systemd.packages = [ pkgs.tayga ];

      systemd.services."tayga@nat64" = {
        overrideStrategy = "asDropin";
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ config.environment.etc."tayga/nat64.conf".source ];
        serviceConfig.User = config.users.users.nat64.name;
      };

      environment.etc."tayga/nat64.conf".text = ''
        tun-device nat64
        ipv4-addr 10.201.0.1
        prefix 64:ff9b::/96
        dynamic-pool 10.201.0.0/16
        wkpf-strict no

        map 44.32.148.18 2a0c:b641:69c:99cc::2
        map 44.32.148.19 2a0c:b641:69c:a230::64
        map 44.32.148.101 2a0c:b641:69c:1600::1
        map 44.32.148.102 2a0c:b641:69c:30e0::1
        map 44.32.148.114 2a0c:b641:69c:8010::1
      '';

      systemd.services."tayga@divi" = {
        overrideStrategy = "asDropin";
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ config.environment.etc."tayga/divi.conf".source ];
        serviceConfig.User = config.users.users.divi.name;
      };

      environment.etc."tayga/divi.conf".text = ''
        tun-device divi
        ipv4-addr 10.200.0.1
        prefix ${cfg.divi.prefix}
        dynamic-pool ${cfg.divi.dynamic-pool}
      '';

      networking.nftables = {
        enable = true;
        tables = {
          gravity = {
            family = "inet";
            content = ''
              define divi_allow = { ${lib.concatStringsSep ", " cfg.divi.allow} }

              chain forward {
                type filter hook forward priority filter; policy accept;
                ip6 daddr ${cfg.divi.prefix} ip6 saddr != $divi_allow reject with icmpv6 admin-prohibited
                tcp flags syn tcp option maxseg size set 1200
              }

              chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                iifname { "stateful", "divi", "nat64" } oifname "${cfg.divi.oif}" ip saddr != { 44.32.148.0/24 } masquerade
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
            curl --fail --retry 5 --retry-delay 30 --retry-connrefused \
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
              "${cfg.srv6.prefix}6::1 encap seg6local action End.DT46 vrftable stateles dev gravity table localsid"
              "${cfg.srv6.prefix}6::2 encap seg6local action End                        dev gravity table localsid"
              "${cfg.srv6.prefix}6::3 encap seg6local action End.DT6  vrftable stateful dev gravity table localsid"
            ];
          in
          {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 r a ${route}") routes;
            ExecStartPost = [
              "${pkgs.iproute2}/bin/ip sr tunsrc set ${cfg.srv6.tunsrc}"
              "${pkgs.iproute2}/bin/ip r add 44.32.148.19 encap seg6 mode encap.red segs 2a0c:b641:69c:a236::1 dev gravity"
            ];
            ExecStop = builtins.map (route: "${pkgs.iproute2}/bin/ip -6 r d ${route}") routes;
            ExecStopPost = [
              "${pkgs.iproute2}/bin/ip sr tunsrc set ::"
              "${pkgs.iproute2}/bin/ip r del 44.32.148.19 encap seg6 mode encap.red segs 2a0c:b641:69c:a236::1 dev gravity"
            ];
          };
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    })
    (mkIf cfg.ipsec.enable {
      sops.secrets.ipsec.sopsFile = ./secrets.yaml;
      environment.systemPackages = [ config.services.strongswan-swanctl.package ];
      environment.etc."ranet/config.json".source = (pkgs.formats.json { }).generate "config.json" (
        {
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
        }
        // lib.optionalAttrs cfg.ipsec.iptfs {
          experimental.iptfs = true;
        }
      );
      systemd.services.gravity-ipsec =
        let
          ranet-exec =
            subcommand:
            utils.escapeSystemdExecArgs [
              "${inputs.ranet-ipsec.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ranet"
              "--config=/etc/ranet/config.json"
              "--registry=/var/lib/gravity/registry.json"
              "--key=${config.sops.secrets.ipsec.path}"
              subcommand
            ];
        in
        {
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ranet-exec "up";
            ExecReload = ranet-exec "up";
            ExecStop = ranet-exec "down";
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
