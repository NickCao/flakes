{ pkgs, config, modulesPath, ... }:
let
  ifname = "ens3";
in
{

  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    kernel.sysctl = {
      "net.ipv6.conf.${ifname}.use_tempaddr" = 0;
    };
  };

  systemd.network.networks = {
    ${ifname} = {
      name = ifname;
      DHCP = "yes";
      extraConfig = ''
        IPv6AcceptRA=yes
        IPv6PrivacyExtensions=no
      '';
    };
  };
}
