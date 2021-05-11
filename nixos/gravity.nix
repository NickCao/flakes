{ config, pkgs, ... }:
{
  environment.etc = {
    "rait/rait.conf".source = config.sops.secrets.rait.path;
    "rait/babeld.conf".text = ''
      random-id true
      local-path-readwrite /run/babeld.ctl
      state-file ""
      pid-file ""
      interface placeholder
      redistribute local deny
    '';
    "rait/bird.conf".text = ''
      ipv6 sadr table sadr6;
      protocol device { }
      protocol static inject {
        ipv6 sadr;
        route 2a0c:b641:69c:99cc::/64 from ::/0 unreachable;
      }
      protocol babel gravity {
        ipv6 sadr {
          import all;
          export where proto = "inject";
        };
        randomize router id;
        vrf "vrf-gravity";
        interface "gravity";
      }
      protocol kernel {
        ipv6 sadr {
          import none;
          export all;
        };
        vrf "vrf-gravity";
        kernel table 100;
      }
    '';
  };

  systemd.services = {
    gravity = {
      serviceConfig = with pkgs;{
        ExecStartPre = [
          "-${iproute}/bin/ip netns add gravity"
          "-${iproute}/bin/ip link add vrf-gravity type vrf table 100"
          "${iproute}/bin/ip link set vrf-gravity up"
          "-${iproute}/bin/ip link add gravity type veth peer host netns gravity"
          "${iproute}/bin/ip link set gravity up master vrf-gravity"
          "${iproute}/bin/ip addr replace 2a0c:b641:69c:99cc::2/128 dev gravity"
          "${iproute}/bin/ip -n gravity link set host up"
          "${iproute}/bin/ip -n gravity link set up lo"
          "${iproute}/bin/ip -n gravity addr replace 2a0c:b641:69c:99cc::1/128 dev lo"
        ];
        ExecStart = "${iproute}/bin/ip netns exec gravity ${babeld}/bin/babeld -c /etc/rait/babeld.conf";
        ExecStartPost = "${rait}/bin/rait up";
        ExecReload = "${rait}/bin/rait sync";
        ExecStopPost = [
          "${rait}/bin/rait down"
          "${iproute}/bin/ip link del gravity"
          "${iproute}/bin/ip link del vrf-gravity"
          "${iproute}/bin/ip netns del gravity"
        ];
      };
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
    gravity-bird = {
      serviceConfig = with pkgs;{
        ExecStart = "${bird2}/bin/bird -d -c /etc/rait/bird.conf";
      };
      after = [ "gravity.service" ];
      partOf = [ "gravity.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
