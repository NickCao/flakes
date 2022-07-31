{ writeShellApplication, qemu, OVMF }:
writeShellApplication {
  name = "qemu-run";
  text = ''
    ${qemu}/bin/qemu-system-x86_64 \
      -machine q35,accel=kvm \
      -cpu host \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      -netdev user,id=net0 \
      -device virtio-net-pci,netdev=net0,disable-legacy=on \
      -audiodev pa,id=snd0 \
      -device ich9-intel-hda \
      -device hda-duplex,audiodev=snd0 \
      -usb \
      -device usb-tablet \
      -device nec-usb-xhci,id=usb \
      -chardev spicevmc,name=usbredir,id=usbredirchardev1 \
      -chardev spicevmc,name=usbredir,id=usbredirchardev2 \
      -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
      -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
      -vga qxl \
      -display spice-app \
      -chardev spicevmc,id=spicechannel0,name=vdagent \
      -device virtio-serial-pci \
      -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      "$@"
  '';
}
