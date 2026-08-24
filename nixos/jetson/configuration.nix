{
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  hardware.nvidia-jetpack = {
    enable = true;
    som = "orin-nano";
    carrierBoard = "devkit";
    majorVersion = "7";
    super = true;
  };

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.podman.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "jetson";

  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji nickcao@mainframe"
  ];

  services.journald.extraConfig = ''
    Storage=volatile
  '';

  environment.baseline.enable = true;

  system.stateVersion = "26.05";
}
