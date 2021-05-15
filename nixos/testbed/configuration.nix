{ pkgs, config, modulesPath, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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
        chain postrouting     {
          type nat hook postrouting priority 100;
          oifname "ens3" masquerade
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

  systemd.network.networks = {
    announce = {
      name = "announce";
      addresses = [
        {
          addressConfig = {
            Address = "2a0c:b641:690::/48";
            PreferredLifetime = 0;
          };
        }
        {
          addressConfig = {
            Address = "2a0c:b641:69c::/48";
            PreferredLifetime = 0;
          };
        }
      ];
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
}
