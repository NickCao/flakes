{ config, pkgs, ... }:
{
  services.gravity = {
    enable = true;
    config = config.sops.secrets.rait.path;
    address = "2a0c:b641:69c:99cc::1/126";
    postStart = [ "${pkgs.iproute2}/bin/ip addr add 2a0c:b641:69c:99cc::2/126 dev gravity" ];
  };
  services.bird2 = {
    enable = true;
    config = ''
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
        interface "gravity";
      }
      protocol kernel {
        ipv6 sadr {
          import none;
          export all;
        };
      }
    '';
  };
}
