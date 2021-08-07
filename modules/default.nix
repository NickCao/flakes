{
  bgp = import ./bgp;
  buyvm = import ./buyvm.nix;
  divi = import ./divi.nix;
  dns = import ./dns;
  gravity = import ./gravity.nix;
  vultr = import ./vultr.nix;
  chasquid = import ./chasquid.nix;
  influxdb2 = import ./influxdb2.nix;
  telegraf = import ./telegraf;
  ss = import ./ss;
  cloud = {
    common = import ./cloud/common.nix;
  };
}
