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
in
{
  services.gravity = {
    enable = true;
    group = 1;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:99cc::1/126";
    postStart = [
      "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:99cc::2/126 dev gravity"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 0x36 lookup main pref 1022"
      "-${pkgs.iproute2}/bin/ip -6 ru add fwmark 0x36 blackhole pref 1023"
      "-${pkgs.iproute2}/bin/ip -6 ru add lookup 101 pref 1024"
      "-${pkgs.iproute2}/bin/ip -6 ru add lookup 100 pref 1025"
    ];
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
          export all;
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
        ExecStart = "${pkgs.v2ray}/bin/v2ray -c ${(pkgs.formats.json {}).generate "config.json" (import ./v2ray.nix)} -c \${CREDENTIALS_DIRECTORY}/secret.json";
    };
  };
}
