rec {
  all = ({ ... }: {
    imports = [
      (import ./metrics.nix)
      (import ./sshcert)
      (import ./dns/secondary)
    ];
  });
  bgp = import ./bgp;
  divi = import ./divi.nix;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  ss = import ./ss;
  cloud = {
    common = import ./cloud/common.nix;
    services = import ./cloud/services.nix;
  };
}
