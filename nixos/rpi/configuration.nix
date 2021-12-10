{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64.nix") ];
  disabledModules = [ "profiles/base.nix" ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    secrets = {
      auth = { };
      etcd = { };
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

  systemd.services.ddns = {
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      EnvironmentFile = config.sops.secrets.etcd.path;
    };
    script = ''
      ${pkgs.etcd_3_4}/bin/etcdctl --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x1 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -4 https://canhazip.com))
      ${pkgs.etcd_3_4}/bin/etcdctl --endpoints https://etcd.nichi.co:443 --user $USER --password $PASSWORD \
        put /dns/link/nichi/dyn/rpi/x2 $(${pkgs.jo}/bin/jo ttl=30 host=$(${pkgs.curl}/bin/curl -s -6 https://canhazip.com))
    '';
  };

  systemd.timers.auth-thu = {
    timerConfig = {
      OnCalendar = "minutely";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.timers.ddns = {
    timerConfig = {
      OnCalendar = "*:0/5";
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
      DHCP = "yes";
      dhcpV6Config = {
        DUIDType = "link-layer";
      };
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
          nrt0.loadBalancer.servers = [{ address = "nrt0.nichi.link:443"; }];
          sin0.loadBalancer.servers = [{ address = "sin0.nichi.link:443"; }];
          sea0.loadBalancer.servers = [{ address = "sea0.nichi.link:443"; }];
        };
      };
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPLArhyazrFjK4Jt/ImHSzICvwKOk4f+7OEcv2HEb7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIpzrZLU0peDu1otGtP2GcCeQIkI8kmfHjnwpbfpWBkv"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 8122 ];
  };
  services.timesyncd.servers = [
    "101.6.6.172" # ntp.tuna.tsinghua.edu.cn
  ];

  environment.systemPackages = with pkgs;[
    socat
    openocd
    picocom
    ffmpeg
  ];

  documentation.nixos.enable = false;
}
