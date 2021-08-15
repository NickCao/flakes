{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64-new-kernel.nix") ];

  networking = {
    hostName = "rpi";
    domain = "nichi.link";
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
  };

  systemd.network.networks = {
    eth0 = {
      name = "eth0";
      DHCP = "yes";
    };
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        api.address = ":40000";
        nrt0.address = ":40001";
        sin0.address = ":40002";
      };
      api = {
        dashboard = true;
      };
    };
    dynamicConfigOptions = {
      http = {
        routers = {
          api = {
            entryPoints = [ "api" ];
            rule = "HostSNI(`*`)";
            service = "api@internal";
          };
        };
      };
      tcp = {
        routers = {
          nrt0 = {
            entryPoints = [ "nrt0" ];
            rule = "HostSNI(`*`)";
            service = "nrt0";
          };
          sin0 = {
            entryPoints = [ "sin0" ];
            rule = "HostSNI(`*`)";
            service = "sin0";
          };
        };
        services = {
          nrt0.loadBalancer.servers = [{ address = "nrt0.nichi.link:41287"; }];
          sin0.loadBalancer.servers = [{ address = "sin0.nichi.link:41287"; }];
        };
      };
    };
  };
}
