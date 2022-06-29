{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
in
dns.lib.toString "scp.link" {
  inherit (common) TTL SOA NS;
  subdomains = {
    "o".NS = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
    vanilla.A = [ "20.24.195.187" ];
    "com".NS = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
  };
}
