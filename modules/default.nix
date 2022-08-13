rec {
  default = ({ ... }: {
    imports = [
      (import ./baseline.nix)
      (import ./gateway.nix)
      (import ./metrics.nix)
      (import ./sshcert)
      (import ./dns/secondary)
      (import ./cloud/services.nix)
      (import ./gravity)
    ];
  });
  vultr = import ./vultr.nix;
  v2ray = import ./v2ray;
  cloud = {
    common = import ./cloud/common.nix;
  };
}
