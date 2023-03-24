{ inputs, ... }: {

  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk.vda = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "boot";
            type = "partition";
            start = "0";
            end = "1M";
            flags = [ "bios_grub" ];
          }
          {
            name = "root";
            type = "partition";
            start = "1M";
            end = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/boot" = { mountOptions = [ "compress=zstd" "noatime" ]; };
                "/nix" = { mountOptions = [ "compress=zstd" "noatime" ]; };
                "/persist" = { mountOptions = [ "compress=zstd" "noatime" ]; };
              };
            };
          }
        ];
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [ "defaults" "mode=755" ];
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;

}
