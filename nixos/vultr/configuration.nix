{ pkgs, config, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
    autoResize = true;
  };
  environment.etc."ssh/keys" = {
    mode = "0555";
    text = ''
      #!${pkgs.runtimeShell}
      ${pkgs.curl}/bin/curl https://gitlab.com/NickCao.keys
    '';
  };
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  networking.firewall.enable = false;
  networking.useNetworkd = true;
  networking.useDHCP = false;
  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain forward {
          type filter hook forward priority 0;
          tcp flags syn tcp option maxseg size set 1300
        }
      }
      table ip nat {
        chain postrouting     {
          type nat hook postrouting priority 100;
          oifname "ens3" masquerade
        }
      }
      table ip6 filter {
        chain forward {
          type filter hook forward priority 0;
          oifname "divi" ip6 saddr != { 2a0c:b641:69c::/48, 2001:470:4c22::/48 } reject
        }
      }
    '';
  };
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';
  systemd.network.networks = {
    ens3 = {
      name = "ens3";
      DHCP = "yes";
      extraConfig = ''
        IPv6AcceptRA=yes
        IPv6PrivacyExtensions=no
      '';
    };
    announce = {
      name = "announce";
      addresses = [
        {
          addressConfig = {
            Address = "2a0c:b641:690::/48";
            PreferredLifetime = 0;
          };
        }
        {
          addressConfig = {
            Address = "2a0c:b641:69c::/48";
            PreferredLifetime = 0;
          };
        }
      ];
    };
  };
  systemd.network.netdevs = {
    announce = {
      netdevConfig = {
        "Name" = "announce";
        "Kind" = "dummy";
      };
    };
  };
  services.openssh = {
    enable = true;
    authorizedKeysCommand = "/etc/ssh/keys";
  };
}
