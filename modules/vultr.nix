{ pkgs, config, modulesPath, ... }:
let
  ifname = "enp1s0";
in
{
  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  systemd.network.networks = {
    "${ifname}" = {
      name = ifname;
      DHCP = "yes";
      networkConfig = {
        KeepConfiguration = "yes";
        IPv6AcceptRA = "yes";
        IPv6PrivacyExtensions = "no";
      };
    };
  };
}
