{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.stalwart;
  settingsFormat = pkgs.formats.json { };
in
{
  disabledModules = [ "services/mail/stalwart.nix" ];

  options.services.stalwart = {
    enable = lib.mkEnableOption "Stalwart, an open-source mail and collaboration server";
    package = lib.mkPackageOption pkgs "stalwart_0_16" { };
    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };
      default = { };
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
        Conflicts = [ "" ];
        ConditionPathExists = [ "" ];
      };
      serviceConfig = {
        ExecStart = [
          ""
          "${lib.getExe cfg.package} --config=${settingsFormat.generate "config.json" cfg.settings}"
        ];
        StateDirectory = "stalwart";
        DynamicUser = true;
      };
    };
  };
}
