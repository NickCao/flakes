{ pkgs, config, modulesPath, ... }:
let
  ifname = "ens3";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
    kernel.sysctl = {
      "net.ipv6.conf.${ifname}.use_tempaddr" = 0;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
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
      extraConfig = ''
        IPv6AcceptRA=yes
        IPv6PrivacyExtensions=no
      '';
    };
  };

  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  users.mutableUsers = false;
}
