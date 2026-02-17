{
  config,
  pkgs,
  utils,
  ...
}:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.ranet.reloadUnits = [ config.systemd.services.gravity.name ];
  };

  systemd.services.gravity =
    let
      ranet-exec =
        subcommand:
        utils.escapeSystemdExecArgs [
          "${pkgs.ranet}/bin/ranet"
          "-c"
          config.sops.secrets.ranet.path
          subcommand
        ];
    in
    {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ranet-exec "up";
        ExecReload = ranet-exec "up";
        ExecStop = ranet-exec "down";
      };
      unitConfig = {
        AssertFileNotEmpty = "/var/lib/gravity/combined.json";
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

  environment.systemPackages = [ pkgs.wireguard-tools ];
}
