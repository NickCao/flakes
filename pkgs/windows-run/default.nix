{ writeShellApplication, qemu, OVMF }:
writeShellApplication {
  name = "windows-run";
  text = ''
    MDEV=/sys/bus/mdev/devices/d577a7cf-2595-44d8-9c08-c67358dcf7ac
    ${qemu.override { smbdSupport = true; hostCpuOnly = true; }}/bin/qemu-system-x86_64 \
      -nodefaults \
      -machine q35,accel=kvm \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      -smp sockets=1,cores=6 -m 8G \
      -cpu host \
      -display gtk,gl=on,show-cursor=on \
      -nic user,model=virtio-net-pci,smb="$HOME/Downloads" \
      -audiodev pa,id=snd0 \
      -device ich9-intel-hda \
      -device hda-duplex,audiodev=snd0 \
      -usb -device usb-tablet \
      -drive if=virtio,file="$HOME"/Documents/vm/windows.img,format=raw \
      -device vfio-pci,sysfsdev="$MDEV",display=on,x-igd-opregion=on,ramfb=on,driver=vfio-pci-nohotplug,romfile="$HOME"/Documents/vm/vbios_gvt_uefi.rom \
      "$@"
  '';
}
