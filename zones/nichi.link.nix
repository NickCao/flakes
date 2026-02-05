{ dns, lib }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) nodes secondary_nameservers;
in
dns.lib.toString "nichi.link" {
  inherit (common)
    TTL
    SOA
    DKIM
    DMARC
    CAA
    SRV
    ;
  NS = common.NS ++ secondary_nameservers;
  MX = with mx; [ (mx 10 "iad0.nichi.link.") ];
  TXT = [ (with spf; soft [ "mx" ]) ];
  subdomains =
    lib.recursiveUpdate
      (builtins.mapAttrs (name: value: {
        A = [ value.ipv4 ];
        AAAA = [ value.ipv6 ];
        HTTPS = [
          {
            svcPriority = 1;
            targetName = ".";
            alpn = [
              "h3"
              "h2"
            ];
            ipv4hint = [ value.ipv4 ];
            ipv6hint = [ value.ipv6 ];
          }
        ];
      }) nodes)
      {
        "iad0" = {
          DMARC = [
            {
              p = "reject";
              sp = "reject";
              pct = 100;
              adkim = "relaxed";
              aspf = "strict";
              fo = [ "1" ];
              ri = 604800;
            }
          ];
        };
      };
}
