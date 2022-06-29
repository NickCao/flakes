{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  he = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
in
dns.lib.toString "scp.link" {
  inherit (common) TTL SOA NS;
  subdomains = {
    vanilla.A = [ "20.24.195.187" ];
    "o".NS = he;
    "com".NS = he;
  };
}
