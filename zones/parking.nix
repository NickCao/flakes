{ dns }:
let
  common = import ./common.nix;
  inherit (common.nodes) nrt0;
in
dns.lib.toString "parking" {
  inherit (common) TTL SOA NS;
  A = [ nrt0.ipv4 ];
  AAAA = [ nrt0.ipv6 ];
}
