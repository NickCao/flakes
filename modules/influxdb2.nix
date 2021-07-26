{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.influxdb2;
  configFile = pkgs.writeText "config.json" (builtins.toJSON cfg.config);
in
{
  options = {
    services.influxdb2 = {
      enable = mkEnableOption "Whether to enable the influxdb2 server";
      package = mkOption {
        default = pkgs.influxdb2;
        defaultText = "pkgs.influxdb2";
        description = "influxdb2 derivation to use";
        type = types.package;
      };
      config = mkOption {
        default = { };
        description = "configuration options for influxdb2";
        type = types.attrs;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = !(builtins.hasAttr "bolt-path" cfg.config) && !(builtins.hasAttr "engine-path" cfg.config);
      message = "services.influxdb2.config: bolt-path and engine-path should not be set as they are managed by systemd";
    }];
    systemd.services.influxdb2 = {
      description = "InfluxDB is an open-source, distributed, time series database";
      documentation = [ "https://docs.influxdata.com/influxdb/" ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      environment = {
        INFLUXD_CONFIG_PATH = "${configFile}";
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/influxd --bolt-path \${STATE_DIRECTORY}/influxd.bolt --engine-path \${STATE_DIRECTORY}/engine";
        StateDirectory = "influxdb2";
        DynamicUser = true;
        CapabilityBoundingSet = "";
        SystemCallFilter = "@system-service";
        LimitNOFILE = 65536;
        KillMode = "control-group";
        Restart = "on-failure";
      };
    };
  };
}
