{
  bgp = import ./bgp;
  divi = import ./divi.nix;
  dns = import ./dns;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  telegraf = import ./telegraf;
  ss = import ./ss;
  sshfp = import ./sshfp;
  cloud = {
    common = import ./cloud/common.nix;
    services = import ./cloud/services.nix;
  };
}
