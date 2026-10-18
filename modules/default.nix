{
  default = (
    { ... }:
    {
      imports = [
        (import ./baseline.nix)
        (import ./caddy.nix)
        (import ./spire-agent.nix)
        (import ./openbao-agent.nix)
        (import ./ghostunnel.nix)
        (import ./metrics)
        (import ./dns/secondary)
        (import ./cloud/services.nix)
        (import ./gravity)
        (import ./backup)
        (import ./stalwart.nix)
      ];
    }
  );
  cloud = {
    disko = import ./cloud/disko.nix;
    disko-uefi = import ./cloud/disko-uefi.nix;
  };
}
