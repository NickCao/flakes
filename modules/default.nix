{
  default = ({ ... }: {
    imports = [
      (import ./baseline.nix)
      (import ./caddy.nix)
      (import ./metrics)
      (import ./dns/secondary)
      (import ./cloud/services.nix)
      (import ./gravity)
      (import ./backup)
    ];
  });
  vultr = import ./vultr.nix;
  cloud = {
    common = import ./cloud/common.nix;
    filesystems = import ./cloud/filesystems.nix;
    disko = import ./cloud/disko.nix;
  };
}
