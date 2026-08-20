{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "usb_storage"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
