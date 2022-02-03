rec {
  all = ({ ... }: {
    imports = [
      (import ./sshcert)
      (import ./dns/secondary)
    ];
  });
  bgp = import ./bgp;
  divi = import ./divi.nix;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  telegraf = import ./telegraf;
  ss = import ./ss;
  cloud = {
    common = import ./cloud/common.nix;
    services = import ./cloud/services.nix;
  };
}
