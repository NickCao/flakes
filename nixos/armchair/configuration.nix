{
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
    hash = "sha256-iYDhbSPE8oO9tny1IUSpViUWx2O7PYr9jpopmftxTzU=";
    message = "
      nix-store --add-fixed sha256 --recursive /efi/asahi/
      nix hash path  --algo sha256             /efi/asahi/
    ";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
  ];

  networking.hostName = "armchair";

  services.openssh.enable = true;

  environment.baseline.enable = true;

  system.stateVersion = "25.05";

}
