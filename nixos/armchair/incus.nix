{
  lib,
  pkgs,
  ...
}:
{
  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      config = {
        "core.https_address" = ":8443";
      };
      storage_pools = lib.singleton {
        name = "default";
        driver = "btrfs";
        config = {
          source = "/var/lib/incus-storage";
        };
      };
      networks = lib.singleton {
        name = "default";
        type = "macvlan";
        config = {
          parent = "end0";
        };
      };
      profiles = lib.singleton {
        name = "default";
        devices = {
          root = {
            type = "disk";
            path = "/";
            pool = "default";
            size = "16GiB";
          };
          eth-1 = {
            type = "nic";
            network = "default";
          };
        };
      };
    };
  };
}
