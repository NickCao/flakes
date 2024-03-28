{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.nodes) hio0;
in
dns.lib.toString "nichi.co" {
  inherit (common) TTL SOA NS DKIM DMARC CAA;
  A = [ hio0.ipv4 ];
  AAAA = [ hio0.ipv6 ];
  MX = with mx; [
    (mx 10 "iad0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  HTTPS = [{
    alpn = [ "h3" "h2" ];
    ipv4hint = [ hio0.ipv4 ];
    ipv6hint = [ hio0.ipv6 ];
  }];
  subdomains = {
    www.TXT = [ "http.cat/404" ];
    id.CNAME = [ "hio0.nichi.link." ];
    fn.CNAME = [ "iad1.nichi.link." ];
    pb.CNAME = [ "hio0.nichi.link." ];
    api.CNAME = [ "iad1.nichi.link." ];
    ntfy.CNAME = [ "iad1.nichi.link." ];
    hydra.CNAME = [ "k17-plct.nichi.link." ];
    cache.CNAME = [ "k17-plct.nichi.link." ];
    vault.CNAME = [ "iad0.nichi.link." ];
    matrix.CNAME = [ "hio0.nichi.link." ];
    syncv3.CNAME = [ "hio0.nichi.link." ];
    mastodon.CNAME = [ "hio0.nichi.link." ];
  };
}
