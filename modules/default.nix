{
  default = (
    { ... }:
    {
      imports = [
        (import ./baseline.nix)
        (import ./caddy.nix)
        (import ./metrics)
        (import ./dns/secondary)
        (import ./cloud/services.nix)
        (import ./gravity)
        (import ./backup)
      ];
    }
  );
  cloud = {
    disko = import ./cloud/disko.nix;
    disko-uefi = import ./cloud/disko-uefi.nix;
  };
}
