{ dns, domain }:
let
  common = import ./common.nix;
  node = (common.nodes).hio0;
in
dns.lib.toString domain {
  inherit (common) TTL SOA NS;
  A = [ node.ipv4 ];
  AAAA = [ node.ipv6 ];
}
