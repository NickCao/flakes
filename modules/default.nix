rec {
  default = ({ ... }: {
    imports = [
      (import ./gateway.nix)
      (import ./metrics.nix)
      (import ./sshcert)
      (import ./dns/secondary)
      (import ./cloud/services.nix)
      gravity
    ];
  });
  bgp = import ./bgp;
  divi = import ./divi.nix;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  v2ray = import ./v2ray;
  cloud = {
    common = import ./cloud/common.nix;
  };
}
