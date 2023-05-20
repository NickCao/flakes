{ dns, lib }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) nodes;
in
dns.lib.toString "nichi.link" {
  inherit (common) TTL SOA NS DKIM DMARC CAA SRV;
  MX = with mx; [
    (mx 10 "iad0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  subdomains = lib.recursiveUpdate (builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes) {
    "iad0" = {
      DMARC = [{
        p = "reject";
        sp = "reject";
        pct = 100;
        adkim = "relaxed";
        aspf = "strict";
        fo = [ "1" ];
        ri = 604800;
        ruf = [ "mailto:postmaster@nichi.co" ];
        rua = [ "mailto:postmaster@nichi.co" ];
      }];
    };
    "rpi".CNAME = [ "rpi.dyn.nichi.link." ];
    "k11-plct".A = [ "8.214.124.155" ];
    "hydra".CNAME = [ "k11-plct.nichi.link." ];
  };
}
