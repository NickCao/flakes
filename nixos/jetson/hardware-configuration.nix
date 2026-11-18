{
  lib,
  pkgs,
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

  boot.kernelPatches = [
    pkgs.kernelPatches.tools_128bit_types
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
