{ config, pkgs, ... }:
let
  china6 = pkgs.runCommand "china6"
    {
      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gaoyifan/china-operator-ip/1535d66331c10102d56712d07531373d8769cf41/china6.txt";
        sha256 = "sha256-NOrG/KP0M17oE7K4bbCE8Q39w3oB8M1cbwBLzstljNY=";
      };
    } ''
    echo "define china6 = {" > $out
    sed '$!s/$/,/' $src >> $out
    echo "}" >> $out
  '';
in
{
  services.gravity = {
    enable = true;
    group = 1;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:99cc::1/126";
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:99cc::2/126 dev gravity"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 0x36 lookup main pref 1024"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 0x36 blackhole pref 1025"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 0x37 lookup main pref 1026"
      "-${pkgs.iproute2}/bin/ip -6 ru add lookup 100 pref 1027"
    ];
  };
  services.bird2 = {
    enable = true;
    config = ''
      router id 169.254.0.1;
      ipv6 sadr table sadr6;
      protocol device { }
      protocol static inject {
        ipv6 sadr;
        route 2a0c:b641:69c:99cc::/64 from ::/0 unreachable;
      }
      protocol babel gravity {
        ipv6 sadr {
          import all;
          export where proto = "inject";
        };
        randomize router id;
        interface "gravity";
      }
      protocol kernel {
        ipv6 sadr {
          import none;
          export all;
        };
        kernel table 100;
      }
    '';
  };
  networking.nftables.enable = true;
  networking.nftables.ruleset = ''
    include "${china6}"
    table ip6 route {
        set china {
            type ipv6_addr
            flags interval
            elements = $china6
        }
        chain china {
            type route hook output priority 0;
            ip6 daddr @china meta mark set 0x37;
        }
        chain nat {
            type nat hook postrouting priority 0;
            masquerade;
        }
    }
  '';
}
