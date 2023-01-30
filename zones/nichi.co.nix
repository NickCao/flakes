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
  SRV = common.SRV ++ [
    {
      service = "matrix";
      proto = "tcp";
      port = 443;
      target = "hio0.nichi.link.";
    }
  ];
  subdomains = {
    www.TXT = [ "http.cat/404" ];
    id.CNAME = [ "iad0.nichi.link." ];
    fn.CNAME = [ "nrt0.nichi.link." ];
    pb.CNAME = [ "sin1.nichi.link." ];
    api.CNAME = [ "nrt0.nichi.link." ];
    git.CNAME = [ "iad0.nichi.link." ];
    red.CNAME = [ "sin1.nichi.link." ];
    ntfy.CNAME = [ "lax0.nichi.link." ];
    hydra.CNAME = [ "k11-plct.nichi.link." ];
    cache.CNAME = [ "k11-plct.nichi.link." ];
    vault.CNAME = [ "iad0.nichi.link." ];
    matrix.CNAME = [ "hio0.nichi.link." ];
  };
}
