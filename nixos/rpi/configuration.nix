{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64-new-kernel.nix") ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    gnupg.sshKeyPaths = [ "/var/lib/sops.key" ];
    secrets = {
      auth = { };
      duckdns = { };
    };
  };

  services.resolved.dnssec = "false";

  systemd.services.auth-thu = {
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      LoadCredential = "auth:${config.sops.secrets.auth.path}";
    };
    script = "${pkgs.auth-thu}/bin/auth-thu -D -c \${CREDENTIALS_DIRECTORY}/auth auth";
  };

  systemd.services.duckdns = {
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.sops.secrets.duckdns.path;
    };
    script = ''
      ${pkgs.curl}/bin/curl -s -4 "https://www.duckdns.org/update?domains=rpi-nichi&token=''${TOKEN}"
    '';
  };

  systemd.timers.auth-thu = {
    timerConfig = {
      OnCalendar = "minutely";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.timers.duckdns = {
    timerConfig = {
      OnCalendar = "*:0/15";
    };
    wantedBy = [ "timers.target" ];
  };

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
      vlan = [ "eth0.10" ];
      dhcpV4Config = {
        RouteMetric = 2048;
      };
    };
    "eth0.10" = {
      name = "eth0.10";
      DHCP = "ipv4"; # dhcpv6 not working due to duid
    };
  };

  systemd.network.netdevs = {
    "eth0.10" = {
      netdevConfig = {
        Name = "eth0.10";
        Kind = "vlan";
      };
      vlanConfig = {
        Id = 10;
      };
    };
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        nrt0.address = ":40001";
        sin0.address = ":40002";
        sea0.address = ":40003";
      };
    };
    dynamicConfigOptions = {
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
          sea0 = {
            entryPoints = [ "sea0" ];
            rule = "HostSNI(`*`)";
            service = "sea0";
          };
        };
        services = {
          nrt0.loadBalancer.servers = [{ address = "nrt0.nichi.link:41287"; }];
          sin0.loadBalancer.servers = [{ address = "sin0.nichi.link:41287"; }];
          sea0.loadBalancer.servers = [{ address = "sea0.nichi.link:41287"; }];
        };
      };
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 8122 ];
  };
  services.timesyncd.servers = [
    "101.6.6.172" # ntp.tuna.tsinghua.edu.cn
  ];

  documentation.nixos.enable = false;
}
