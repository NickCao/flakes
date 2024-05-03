{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
in
dns.lib.toString "scp.link" {
  inherit (common) TTL SOA NS;
  A = [
    "185.199.108.153"
    "185.199.109.153"
    "185.199.110.153"
    "185.199.111.153"
  ];
  AAAA = [
    "2606:50c0:8000::153"
    "2606:50c0:8001::153"
    "2606:50c0:8002::153"
    "2606:50c0:8003::153"
  ];
  subdomains.www = {
    CNAME = [ "nickcao.github.io." ];
  };
}