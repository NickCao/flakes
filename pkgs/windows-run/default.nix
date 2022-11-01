{ writeShellApplication, qemu, OVMF }:
writeShellApplication {
  name = "windows-run";
  text = ''
    ${qemu.override { smbdSupport = true; hostCpuOnly = true; }}/bin/qemu-system-x86_64 \
      -nodefaults \
      -machine q35,accel=kvm \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      -vga qxl -device virtio-serial-pci \
      -spice unix=on,addr=/tmp/windows.socket,disable-ticketing=on \
      -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
      -chardev spicevmc,id=spicechannel0,name=vdagent \
      -device ich9-usb-ehci1,id=usb \
      -device ich9-usb-uhci1,masterbus=usb.0,firstport=0,multifunction=on \
      -device ich9-usb-uhci2,masterbus=usb.0,firstport=2 \
      -device ich9-usb-uhci3,masterbus=usb.0,firstport=4 \
      -chardev spicevmc,name=usbredir,id=usbredirchardev1 -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1 \
      -chardev spicevmc,name=usbredir,id=usbredirchardev2 -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2 \
      -chardev spicevmc,name=usbredir,id=usbredirchardev3 -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3 \
      -smp sockets=1,cores=6 -m 8G \
      -cpu host \
      -nic user,model=virtio-net-pci,smb="$HOME/Downloads" \
      -audiodev pa,id=snd0 \
      -device ich9-intel-hda \
      -device hda-duplex,audiodev=snd0 \
      -usb -device usb-tablet \
      -drive if=virtio,file="$HOME"/Documents/vm/windows.img,format=raw \
      "$@"
  '';
}
