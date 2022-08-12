{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) nodes;
in
dns.lib.toString "nichi.link" {
  inherit (common) TTL SOA NS DKIM DMARC CAA;
  MX = with mx; [
    (mx 10 "hel0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  subdomains = builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes // {
    "rpi".CNAME = [ "rpi.dyn.nichi.link." ];
    "k11-plct".A = [ "8.214.124.155" ];
  };
}
