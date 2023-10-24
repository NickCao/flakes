{ ... }:
let
  device = "/dev/disk/by-partlabel/NIXOS";
  fsType = "btrfs";
  options = [ "relatime" "compress-force=zstd" "space_cache=v2" ];
in
{
  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "defaults" "mode=755" ];
    };

    "/boot" = {
      inherit device fsType;
      options = [ "subvol=boot" ] ++ options;
    };

    "/nix" = {
      inherit device fsType;
      options = [ "subvol=nix" ] ++ options;
    };

    "/persist" = {
      inherit device fsType;
      options = [ "subvol=persist" ] ++ options;
      neededForBoot = true;
    };
  };
}
