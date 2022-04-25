{ config, pkgs, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ "gravity.service" ];
  };

  boot.kernel.sysctl = {
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.tcp_l3mdev_accept" = 0;
    "net.ipv4.udp_l3mdev_accept" = 0;
    "net.ipv4.raw_l3mdev_accept" = 0;
  };

  systemd.services.gravity = {
    serviceConfig = with pkgs;{
      ExecStart = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} up";
      ExecReload = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} up";
      ExecStop = "${ranet}/bin/ranet -c ${config.sops.secrets.ranet.path} down";
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.network.enable = true;
  systemd.network.netdevs.gravity = {
    netdevConfig = {
      Name = "gravity";
      Kind = "vrf";
    };
    vrfConfig = {
      Table = 200;
    };
  };
  systemd.services.fix-ip-rules = {
    path = with pkgs;[ iproute2 coreutils ];
    script = ''
      ip -4 ru del pref 0 || true
      ip -6 ru del pref 0 || true
      if [ -z "$(ip -4 ru list pref 2000)" ]; then
        ip -4 ru add pref 2000 l3mdev unreachable proto kernel
      fi
      if [ -z "$(ip -6 ru list pref 2000)" ]; then
        ip -6 ru add pref 2000 l3mdev unreachable proto kernel
      fi
    '';
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.network.networks.gravity = {
    name = "gravity";
    addresses = [{ addressConfig.Address = "2a0c:b641:69c:4ed0::1/60"; }];
    routingPolicyRules = [
      {
        routingPolicyRuleConfig = {
          Priority = 3000;
          Table = "local";
          Family = "both";
        };
      }
    ];
  };

  services.bird2 = {
    enable = true;
    config = ''
      ipv6 sadr table sadr6;
      protocol device {
        scan time 5;
      }
      protocol direct {
        ipv6 sadr;
        interface "gravity";
      }
      protocol kernel {
        kernel table 200;
        ipv6 sadr {
          export all;
          import none;
        };
      }
      protocol babel gravity {
        vrf "gravity";
        ipv6 sadr {
          export all;
          import all;
        };
        randomize router id;
        interface "grv*" {
          type tunnel;
          rxcost 32;
          hello interval 20 s;
          rtt cost 1024;
          rtt max 1024 ms;
        };
      }
    '';
  };
}
