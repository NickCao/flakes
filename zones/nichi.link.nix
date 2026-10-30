{ dns, lib }:
let
  common = import ./common.nix;
  inherit (common) nodes secondary_nameservers;
in
dns.lib.toString "nichi.link" {
  inherit (common)
    TTL
    SOA
    CAA
    SRV
    ;
  NS = common.NS ++ secondary_nameservers;
  subdomains =
    lib.recursiveUpdate
      (builtins.mapAttrs (name: value: {
        A = [ value.ipv4 ];
        AAAA = [ value.ipv6 ];
      }) nodes)
      {
        "armchair" = {
          A = [ "44.32.148.19" ];
          AAAA = [ "2a0c:b641:69c:a230::1" ];
        };
        "subframe" = {
          A = [ "44.32.148.20" ];
          AAAA = [ "2a0c:b641:69c:6550::1" ];
        };
      };
}
