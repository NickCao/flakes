{ config, pkgs, ... }:
{
  sops.secrets.ranet = { };

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
      ip -4 ru del pref 0
      ip -6 ru del pref 0
      ip -4 ru add pref 2000 l3mdev unreachable proto kernel
      ip -6 ru add pref 2000 l3mdev unreachable proto kernel
    '';
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
  };
  systemd.network.networks.gravity = {
    name = "gravity";
    addresses = [{ addressConfig.Address = "2a0c:b641:69c:99cc::1/64"; }];
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
      router id 169.254.0.1;
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

  systemd.services.v2ray = {
    description = "a platform for building proxies to bypass network restrictions";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      LoadCredential = "secret.json:${config.sops.secrets.v2ray.path}";
      DynamicUser = true;
      ExecStart = "${pkgs.v2ray}/bin/v2ray run -c ${(pkgs.formats.json {}).generate "config.json" (import ./v2ray.nix)} -c \${CREDENTIALS_DIRECTORY}/secret.json";
    };
  };
}
