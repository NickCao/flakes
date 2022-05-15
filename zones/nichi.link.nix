{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) nodes;
in
dns.lib.toString "nichi.link" {
  inherit (common) TTL SOA NS DKIM DMARC;
  MX = with mx; [
    (mx 10 "hel0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  subdomains = builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes // {
    "hel0" = host "65.21.32.182" "2a01:4f9:3a:40c9::1";
    "nrt.jp".CNAME = [ "nrt0.nichi.link." ];
    "sin.sg".CNAME = [ "sin0.nichi.link." ];
    "rpi".CNAME = [ "rpi.dyn.nichi.link." ];
    "k11-plct".A = [ "8.214.124.155" ];
  };
}
