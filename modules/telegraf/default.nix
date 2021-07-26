{ config, pkgs, lib, ... }:
with lib;
{
  sops.secrets.telegraf = {
    sopsFile = ./secrets.yaml;
  };
  systemd.services.telegraf = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.telegraf.path;
      DynamicUser = true;
      ExecStart = "${pkgs.telegraf}/bin/telegraf -config https://stats.nichi.co/api/v2/telegrafs/07e44bec596d9000";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartForceExitStatus = "SIGPIPE";
      KillMode = "control-group";
    };
  };
}
