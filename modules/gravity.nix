{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.gravity;
in
{
  options.services.gravity = {
    enable = mkEnableOption "gravity overlay network";
    config = mkOption {
      type = types.path;
      description = "path to rait config";
    };
    address = mkOption {
      type = types.str;
      description = "address to add into netns (as icmp source address)";
    };
    netns = mkOption {
      type = types.str;
      description = "name of netns for wireguard interfaces";
      default = "gravity";
    };
    link = mkOption {
      type = types.str;
      description = "name of link connecting netns";
      default = "gravity";
    };
    group = mkOption {
      type = types.int;
      description = "ifgroup of link connecting netns";
      default = 0;
    };
    socket = mkOption {
      type = types.str;
      description = "path of babeld control socket";
      default = "/run/babeld.ctl";
    };
    postStart = mkOption {
      type = types.listOf types.str;
      description = "additional commands to run after startup";
      default = [ ];
    };
  };
  config = mkIf cfg.enable {
    systemd.services.gravity = {
      serviceConfig = with pkgs;{
        ExecStartPre = [
          "${iproute2}/bin/ip netns add ${cfg.netns}"
          "${iproute2}/bin/ip link add ${cfg.link} group ${toString cfg.group} type veth peer host netns ${cfg.netns}"
          "${iproute2}/bin/ip link set ${cfg.link} up"
          "${iproute2}/bin/ip -n ${cfg.netns} link set host up"
          "${iproute2}/bin/ip -n ${cfg.netns} addr add ${cfg.address} dev host"
        ];
        ExecStart = "${iproute2}/bin/ip netns exec ${cfg.netns} ${babeld}/bin/babeld -c ${writeText "babeld.conf" ''
          random-id true
          local-path-readwrite ${cfg.socket}
          state-file ""
          pid-file ""
          interface placeholder
          redistribute local deny
        ''}";
        ExecStartPost = [
          "${rait}/bin/rait up -c ${cfg.config}"
        ] ++ cfg.postStart;
        ExecReload = "${rait}/bin/rait sync -c ${cfg.config}";
        ExecStopPost = "${iproute2}/bin/ip netns del ${cfg.netns}";
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
