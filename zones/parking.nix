{ dns }:
let
  common = import ./common.nix;
  lax0 = (common.nodes).lax0;
in
dns.lib.toString "parking" {
  inherit (common) TTL SOA NS;
  A = [ lax0.ipv4 ];
  AAAA = [ lax0.ipv6 ];
}
