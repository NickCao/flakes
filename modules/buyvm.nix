{ config, lib, pkgs, modulesPath, ... }:
let
  ifname = "ens3";
in
{
  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "virtio_blk" ];
    kernelModules = [ "kvm-amd" ];
  };

  systemd.network.networks = {
    ${ifname} = {
      name = ifname;
      DHCP = "yes";
    };
  };
}
