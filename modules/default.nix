{
  bgp = import ./bgp;
  buyvm = import ./buyvm.nix;
  divi = import ./divi.nix;
  dns = import ./dns;
  gravity = import ./gravity.nix;
  image = import ./image.nix;
  ssh = import ./ssh.nix;
  vultr = import ./vultr.nix;
  chasquid = import ./chasquid.nix;
  influxdb2 = import ./influxdb2.nix;
  telegraf = import ./telegraf;
}
