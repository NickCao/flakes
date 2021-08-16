{ config, lib, pkgs, modulesPath, ... }:
let
  toplevel = config.system.build.toplevel;
in
{
  system.build.unifiedKernelImage = pkgs.runCommand "linux.efi"
    {
      nativeBuildInputs = with pkgs;[ binutils ];
      kernelParams = config.boot.kernelParams;
    } ''
    echo "init=${toplevel}/init $kernelParams" > cmdline
    objcopy \
      --add-section .osrel="${config.environment.etc.os-release.source}" --change-section-vma .osrel=0x20000 \
      --add-section .cmdline="cmdline" --change-section-vma .cmdline=0x30000 \
      --add-section .linux="${toplevel}/kernel" --change-section-vma .linux=0x2000000 \
      --add-section .initrd="${toplevel}/initrd" --change-section-vma .initrd=0x3000000 \
      "${pkgs.systemd}/lib/systemd/boot/efi/linuxx64.efi.stub" "$out"
  '';
}
