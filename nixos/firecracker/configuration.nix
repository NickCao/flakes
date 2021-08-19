{ config, pkgs, lib, ... }:
let
  kernelBase = pkgs.linux_latest;
  /*
  kernelPackages = pkgs.linuxPackages_custom {
    inherit (kernelBase) version src;
    configfile = pkgs.linuxConfig {
      inherit (kernelBase) src;
      makeTarget = "tinyonfig";
    };
  };
  */
  kernelPackages = pkgs.linuxPackages_latest;
  extract-vmlinux = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/d6d09a6942050f21b065a134169002b4d6b701ef/scripts/extract-vmlinux";
    sha256 = "sha256-l8/u61HeF/S1koxUQrVuVYExTd7zzt8lI74gSdeTlK8=";
  };
in
{
  boot.kernelPackages = kernelPackages;
  system.build.rawkernel = pkgs.runCommand "vmlinux" { nativeBuildInputs = with pkgs;[ binutils bzip2 zstd ]; } ''
    ${pkgs.bash}/bin/sh ${extract-vmlinux} ${config.boot.kernelPackages.kernel}/bzImage > $out
  '';
}
