{ config, pkgs, ... }:
let
  china6 = pkgs.runCommand "china6"
    {
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/1535d66331c10102d56712d07531373d8769cf41/china6.txt";
        sha256 = "sha256-NOrG/KP0M17oE7K4bbCE8Q39w3oB8M1cbwBLzstljNY=";
      };
    } ''
    sed 's/^/route /;s/$/ recursive 2001:db8::1;/' $src >> $out
  '';
  raitConfig = pkgs.writeText "rait.conf" ''
    registry     = env("REGISTRY")
    operator_key = env("OPERATOR_KEY")
    private_key  = env("PRIVATE_KEY")
    namespace    = "gravity"

    transport {
      address_family = "ip4"
      send_port      = 50153
      mtu            = 1400
      ifprefix       = "grv4x"
      ifgroup        = 1
      fwmark         = 54
      random_port    = false
    }

    transport {
      address_family = "ip6"
      send_port      = 50154
      mtu            = 1400
      ifprefix       = "grv6x"
      ifgroup        = 2
      fwmark         = 54
      random_port    = false
    }

    babeld {
      enabled = false
    }

    remarks = {
      location = "thu"
      operator = "nickcao"
    }
  '';
in
{
  systemd.services.gravity = {
    serviceConfig = with pkgs;{
      EnvironmentFile = config.sops.secrets.rait.path;
      ExecStartPre = [
        "${iproute2}/bin/ip netns add gravity"
        "${iproute2}/bin/ip netns exec gravity ${procps}/bin/sysctl -w net.ipv6.conf.all.forwarding=1"
        "${iproute2}/bin/ip netns exec gravity ${procps}/bin/sysctl -w net.ipv6.conf.default.forwarding=1"
        "${iproute2}/bin/ip link add gravity address 00:00:00:00:00:02 group 1 type veth peer host address 00:00:00:00:00:01 netns gravity"
        "${iproute2}/bin/ip link set gravity up"
        "${iproute2}/bin/ip -n gravity link set host up"
        "${iproute2}/bin/ip -n gravity addr add 2a0c:b641:69c:99cc::1/126 dev host"
        "${rait}/bin/rait up -c ${raitConfig}"
      ];
      ExecStart = "${iproute2}/bin/ip netns exec gravity ${bird-babel-rtt}/bin/bird -f -s /run/gravity.ctl -c ${writeText "bird.conf" ''
        router id 10.0.0.1;
        ipv6 sadr table sadr6;
        protocol device {
          scan time 5;
        }
        protocol kernel {
          ipv6 sadr {
            export all;
            import none;
          };
        }
        protocol babel {
          ipv6 sadr {
            export all;
            import all;
          };
          interface "host" {
            type wired;
          };
          interface "grv*" {
            type tunnel;
            rxcost 32;
            hello interval 20 s;
            rtt max 1024 ms;
          };
        }
      ''}";
      ExecReload = "${rait}/bin/rait sync -c ${raitConfig}";
      ExecStopPost = "${iproute2}/bin/ip netns del gravity";
      Restart = "always";
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.network.enable = true;
  systemd.network.networks = {
    gravity = {
      name = "gravity";
      addresses = [{ addressConfig.Address = "2a0c:b641:69c:99cc::2/126"; }];
      dns = [ "2a0c:b641:69c:f254:0:5:0:3" "2a0c:b641:69c:7864:0:5:0:3" ];
      domains = [ "~gravity" ];
      networkConfig = {
        DNSSEC = false;
      };
      routingPolicyRules = [
        {
          routingPolicyRuleConfig = {
            FirewallMark = 54;
            Priority = 1022;
            Family = "ipv6";
          };
        }
        {
          routingPolicyRuleConfig = {
            FirewallMark = 54;
            Priority = 1023;
            Family = "ipv6";
            Type = "blackhole";
          };
        }
        {
          routingPolicyRuleConfig = {
            Table = 101;
            Priority = 1024;
            Family = "ipv6";
          };
        }
        {
          routingPolicyRuleConfig = {
            Table = 100;
            Priority = 1025;
            Family = "ipv6";
          };
        }
      ];
    };
  };

  services.bird2 = {
    enable = true;
    config = ''
      router id 169.254.0.1;
      ipv6 sadr table sadr6;
      ipv6 table china6;
      protocol device { }
      protocol static inject {
        ipv6 sadr;
        route 2a0c:b641:69c:99cc::/64 from ::/0 unreachable;
      }
      protocol static workaround {
        ipv6 sadr;
        route ::/0 from ::/0 via fe80::200:ff:fe00:1%gravity;
      }
      protocol babel gravity {
        ipv6 sadr {
          import all;
          export where proto = "inject";
        };
        randomize router id;
        interface "gravity";
      }
      protocol static china6_static {
        ipv6 {
          table china6;
        };
        igp table master6;
        include "${china6}";
      }
      protocol kernel gravity_kernel {
        ipv6 sadr {
          import none;
          export filter {
            krt_prefsrc = 2a0c:b641:69c:99cc::2;
            accept;
          };
        };
        kernel table 100;
      }
      protocol kernel china6_kernel {
        ipv6 {
          table china6;
          import none;
          export all;
        };
        kernel table 101;
      }
      protocol kernel master6_kernel {
        ipv6 {
          import all;
          export all;
        };
        learn;
      }
    '';
  };

  systemd.services.v2ray = {
    description = "a platform for building proxies to bypass network restrictions";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      LoadCredential = "secret.json:${config.sops.secrets.v2ray.path}";
      DynamicUser = true;
      ExecStart = "${pkgs.v2ray}/bin/v2ray run -c ${(pkgs.formats.json {}).generate "config.json" (import ./v2ray.nix)} -c \${CREDENTIALS_DIRECTORY}/secret.json";
    };
  };
}
