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

  networking.hostName = "armchair";

  system.stateVersion = "25.05"; # Did you read the comment?

}
