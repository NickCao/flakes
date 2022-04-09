rec {
  default = ({ ... }: {
    imports = [
      (import ./gateway.nix)
      (import ./metrics.nix)
      (import ./sshcert)
      (import ./divi.nix)
      (import ./dns/secondary)
      (import ./cloud/services.nix)
      gravity
    ];
  });
  bgp = import ./bgp;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  v2ray = import ./v2ray;
  cloud = {
    common = import ./cloud/common.nix;
  };
}
