{
  config,
  lib,
  pkgs,
  ...
}:

{

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };

  hardware.asahi.peripheralFirmwareDirectory = pkgs.requireFile {
    name = "asahi";
    hashMode = "recursive";
    hash = "sha256-Y7z8yGQOiohhOSzYS2LA04PSDcul3cYOsF72IzMIbXk=";
    message = "";
  };

  users.mutableUsers = lib.mkForce true;

  networking.hostName = "armchair";

  environment.baseline.enable = true;

  system.stateVersion = "25.05";

}
