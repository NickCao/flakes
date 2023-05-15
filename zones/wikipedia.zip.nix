{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.nodes) hio0;
in
dns.lib.toString "scp.link" {
  inherit (common) TTL SOA NS;
  A = [ hio0.ipv4 ];
  AAAA = [ hio0.ipv6 ];
}
