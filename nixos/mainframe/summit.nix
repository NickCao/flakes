{
  lib,
  pkgs,
  utils,
  ...
}:
{
  # allow non-root user to bind to tftp port
  boot.kernel.sysctl = {
    "net.ipv4.ip_unprivileged_port_start" = 0;
  };

  networking.hosts = {
    "127.0.0.1" = [
      "jumpstarter-grpc.jumpstarter-lab.svc.cluster.local"
      "jumpstarter-router-grpc.jumpstarter-lab.svc.cluster.local"
    ];
  };

  systemd.network.networks = {
    "09-ti" = {
      name = "enp195s0f4u1";
      networkConfig = {
        ConfigureWithoutCarrier = true;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        ServerAddress = "192.168.0.1/24";
      };
    };
  };

  home-manager.users.nickcao = {
    systemd.user.services =
      let
        mkExec =
          svc: port:
          utils.escapeSystemdExecArgs [
            (lib.getExe pkgs.kubectl)
            "port-forward"
            "-n"
            "jumpstarter-lab"
            svc
            port
          ];
      in
      {
        jumpstarter-grpc = {
          Service = {
            ExecStart = mkExec "services/jumpstarter-grpc" "8082:8082";
            Restart = "always";
          };
          Install.WantedBy = [ "default.target" ];
        };
        jumpstarter-router-grpc = {
          Service = {
            ExecStart = mkExec "services/jumpstarter-router-grpc" "8083:8083";
            Restart = "always";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };

}
