{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  he = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
in
dns.lib.toString "scp.link" {
  inherit (common) TTL SOA NS;
  MX = with mx; [ (mx 10 "hel1.nichi.link.") ];
  subdomains = {
    "mail".CNAME = [ "hel1.nichi.link." ];
    "o".NS = he;
    "com".NS = he;
    "t".NS = he;
  };
}
