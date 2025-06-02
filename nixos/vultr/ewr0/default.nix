{
  lib,
  pkgs,
  utils,
  ...
}:
{
  cloud.services.armchair.config = {
    ExecStart = utils.escapeSystemdExecArgs [
      (lib.getExe pkgs.socat)
      "TCP-LISTEN:9022,fork,reuseaddr"
      "TCP-CONNECT:[2a0c:b641:69c:a230::1]:22,so-bindtodevice=gravity"
    ];
  };
}
