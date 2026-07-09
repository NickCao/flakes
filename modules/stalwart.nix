{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.stalwart;
  applyCfg = config.services.stalwart.apply;
  settingsFormat = pkgs.formats.json { };
in
{
  disabledModules = [ "services/mail/stalwart.nix" ];

  options.services.stalwart = {
    enable = lib.mkEnableOption "Stalwart, an open-source mail and collaboration server";
    package = lib.mkPackageOption pkgs "stalwart_0_16" { };
    credentialFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      default = { };
    };
    apply = {
      enable = lib.mkEnableOption "Stalwart declarative configuration";
      credentialFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
      plan = lib.mkOption {
        type = lib.types.listOf settingsFormat.type;
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.stalwart.settings = {
      "@type" = lib.mkDefault "RocksDb";
      path = lib.mkDefault "/var/lib/stalwart";
    };

    systemd.packages = [ cfg.package ];

    systemd.services.stalwart = {
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        # Conflicts = [ "" ];
        ConditionPathExists = [ "" ];
      };
      serviceConfig = {
        ExecStart = [
          ""
          "${lib.getExe cfg.package} --config=${settingsFormat.generate "config.json" cfg.settings}"
        ];
        StateDirectory = "stalwart";
        DynamicUser = true;
      }
      // lib.optionalAttrs (cfg.credentialFile != null) {
        EnvironmentFile = cfg.credentialFile;
      };
    };

    systemd.services.stalwart-apply = lib.mkIf applyCfg.enable {
      description = "Apply Stalwart configuration";
      after = [ "stalwart.service" ];
      requires = [ "stalwart.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = applyCfg.credentialFile;
        RuntimeDirectory = [ "stalwart-apply" ];
        Environment = [ "HOME=%t/stalwart-apply" ];
        ExecStart = "${lib.getExe pkgs.stalwart-cli} apply --file ${
          pkgs.writeText "plan.ndjson" (lib.concatMapStringsSep "\n" (op: builtins.toJSON op) applyCfg.plan)
        }";
        Restart = "on-failure";
        RestartSec = 3;
      }
      // lib.optionalAttrs (applyCfg.credentialFile != null) {
        EnvironmentFile = applyCfg.credentialFile;
      };
    };
  };
}
