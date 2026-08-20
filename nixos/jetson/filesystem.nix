{
  ...
}:

{
  disko.devices = {
    disk = {
      primary = {
        type = "disk";
        device = "/dev/disk/by-id/usb-ASolid_USB_2606130763420046-0:0";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              label = "ESP";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              label = "ROOT";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress-force=zstd" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress-force=zstd" ];
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=2G"
          "mode=755"
          "nosuid"
          "nodev"
        ];
      };
    };
  };

  environment.persistence."/persist" = {
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    directories = [
      "/var"
      "/root"
      "/home"
    ];
  };

  fileSystems."/persist".neededForBoot = true;

  boot.loader.efi.efiSysMountPoint = "/efi";
}
