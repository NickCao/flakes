{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.network.netdevs = {
    "10-end0macvlan" = {
      netdevConfig = {
        Kind = "macvlan";
        Name = "end0macvlan";
      };
      macvlanConfig = {
        Mode = "bridge";
      };
    };
  };

  systemd.network.networks = {
    "10-end0" = {
      name = "end0";
      macvlan = [
        config.systemd.network.netdevs."10-end0macvlan".netdevConfig.Name
      ];
    };
    "10-end0macvlan" = {
      name = config.systemd.network.netdevs."10-end0macvlan".netdevConfig.Name;
      DHCP = "yes";
      dhcpV4Config.RouteMetric = 512;
      ipv6AcceptRAConfig.RouteMetric = 512;
    };
  };

  systemd.network.wait-online = {
    anyInterface = true;
    extraArgs = [ "--ipv4" ];
  };

  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = ":8443";
      };
      storage_pools = lib.singleton {
        name = "default";
        driver = "btrfs";
        config = {
          source = "/var/lib/incus-storage";
        };
      };
      networks = lib.singleton {
        name = "default";
        type = "macvlan";
        config = {
          parent = "end0";
        };
      };
      profiles = lib.singleton {
        name = "default";
        devices = {
          root = {
            type = "disk";
            path = "/";
            pool = "default";
            size = "16GiB";
          };
          eth-1 = {
            type = "nic";
            network = "default";
          };
        };
      };
    };
  };
}
