{ config, lib, pkgs, modulesPath, ... }:
let
  ifname = "ens3";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    loader.grub.device = "/dev/vda";
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "virtio_blk" ];
    kernelModules = [ "kvm-amd" ];
    kernel.sysctl = {
      "net.ipv6.conf.${ifname}.use_tempaddr" = 0;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
  };

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = "";
    };
  };

  systemd.network.networks = {
    ${ifname} = {
      name = ifname;
      DHCP = "yes";
    };
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  users.mutableUsers = false;
}
