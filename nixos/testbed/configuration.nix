{ pkgs, config, modulesPath, ... }:
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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
