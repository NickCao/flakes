{ pkgs, config, modulesPath, ... }:
let
  ifname = "enp1s0";
in
{
  boot = {
    initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  };

  system.activationScripts.bootstrap-secrets = pkgs.lib.stringAfter [ "users" ] ''
    echo bootstrap secrets...
    ${pkgs.curl}/bin/curl -s http://169.254.169.254/latest/user-data -o /var/lib/sops.key
  '';

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
