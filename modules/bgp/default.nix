{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.bgp;
in
{
  options.services.bgp = {
    enable = mkEnableOption "bird2 bgp announcement";
    node = mkOption {
      type = types.str;
      description = "node prefix";
    };
    prefixes = mkOption {
      type = types.listOf types.str;
      description = "prefixes to announce";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets.bgp_passwd = {
      sopsFile = ./secrets.yaml;
      owner = "bird2";
    };
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    systemd.network.networks = {
      announce = {
        name = "announce";
        addresses = builtins.map
          (
            p:
            {
              addressConfig = {
                Address = p;
                PreferredLifetime = 0;
              };
            }
          )
          cfg.prefixes;
      };
    };
    systemd.network.netdevs = {
      announce = {
        netdevConfig = {
          "Name" = "announce";
          "Kind" = "dummy";
        };
      };
    };
    systemd.services.bird2.restartTriggers = [ (builtins.hashFile "sha256" ./secrets.yaml) ];
    services.bird2 = {
      enable = true;
      checkConfig = false;
      config = ''
        include "${config.sops.secrets.bgp_passwd.path}";
        ipv6 sadr table sadr6;
        protocol device { }
        protocol static inject {
          ipv6 sadr;
          route ::/0 from 2a0c:b641:69c::/48 unreachable;
          route ${cfg.node} from ::/0 unreachable;
        }
        protocol babel gravity {
          ipv6 sadr {
            import all;
            export where proto = "inject";
          };
          randomize router id on;
          interface "gravity";
        }
        protocol kernel {
          ipv6 sadr {
            import none;
            export where proto = "gravity";
          };
        }
        protocol direct announce {
          ipv6;
          interface "announce";
        }
        filter outbound
        {
          if proto != "announce" then reject;
          bgp_community.add((64603, 6939));
          bgp_community.add((64602, 13335));
          accept;
        }
        protocol bgp vultr {
          ipv6 {
            import none;
            export filter outbound;
          };
          local as 209297;
          graceful restart on;
          multihop 2;
          neighbor 2001:19f0:ffff::1 as 64515;
          password BGP_PASSWD;
        }
      '';
    };
  };
}
