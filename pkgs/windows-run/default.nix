{ writeShellApplication, qemu, OVMF }:
writeShellApplication {
  name = "windows-run";
  text = ''
    MDEV=/sys/bus/mdev/devices/d577a7cf-2595-44d8-9c08-c67358dcf7ac
    ${qemu.override { smbdSupport = true; hostCpuOnly = true; }}/bin/qemu-system-x86_64 \
      -nodefaults \
      -machine q35,accel=kvm \
      -smp sockets=1,cores=6 -m 8G \
      -cpu host \
      -display gtk,gl=on,show-cursor=on \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      -netdev user,id=net0,smb="$HOME/Downloads" \
      -device virtio-net-pci,netdev=net0,disable-legacy=on \
      -audiodev pa,id=snd0 \
      -device ich9-intel-hda \
      -device hda-duplex,audiodev=snd0 \
      -usb -device usb-tablet \
      -drive if=none,id=root,file="$HOME"/Documents/vm/windows.img,format=raw \
      -device virtio-blk-pci,drive=root,disable-legacy=on \
      -device vfio-pci,sysfsdev="$MDEV",display=on,x-igd-opregion=on,ramfb=on,driver=vfio-pci-nohotplug,romfile="$HOME"/Documents/vm/vbios_gvt_uefi.rom \
      "$@"
  '';
}
