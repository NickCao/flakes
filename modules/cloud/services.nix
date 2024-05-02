{ config, lib, ... }:
with lib;
let
  cfg = config.cloud;
  mkService =
    {
      enable,
      serviceConfig,
      unitConfig,
    }:
    {
      serviceConfig = {
        MemoryHigh = "300M";
        MemoryMax = "400M";
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateUsers = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectProc = "invisible";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        CapabilityBoundingSet = "";
        ProtectHostname = true;
        ProcSubset = "pid";
        SystemCallArchitectures = "native";
        UMask = "0077";
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
        Restart = "always";
      } // serviceConfig;
      unitConfig = { } // unitConfig;
      wantedBy = lib.optionals enable [ "multi-user.target" ];
    };
  serviceOptions =
    { config, ... }:
    {
      options = {
        enable = mkOption { default = true; };
        config = mkOption { default = { }; };
        unit = mkOption { default = { }; };
      };
    };
in
{
  options = {
    cloud.services = mkOption {
      default = { };
      type = with types; attrsOf (submodule serviceOptions);
    };
  };
  config = {
    systemd.services = builtins.mapAttrs (
      name: v:
      mkService {
        enable = v.enable;
        serviceConfig = v.config;
        unitConfig = v.unit;
      }
    ) cfg.services;
  };
}
