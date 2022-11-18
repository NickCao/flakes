{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.nodes) hel0;
in
dns.lib.toString "nichi.co" {
  inherit (common) TTL SOA NS DKIM DMARC CAA;
  A = [ hel0.ipv4 ];
  AAAA = [ hel0.ipv6 ];
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
      target = "hel0.nichi.link.";
    }
  ];
  subdomains = {
    www.TXT = [ "http.cat/404" ];
    fn.CNAME = [ "nrt0.nichi.link." ];
    pb.CNAME = [ "sin1.nichi.link." ];
    api.CNAME = [ "nrt0.nichi.link." ];
    git.CNAME = [ "hel0.nichi.link." ];
    red.CNAME = [ "sin1.nichi.link." ];
    ntfy.CNAME = [ "hel0.nichi.link." ];
    hydra.CNAME = [ "sin1.nichi.link." ];
    cache.CNAME = [ "sin1.nichi.link." ];
    vault.CNAME = [ "hel0.nichi.link." ];
    matrix.CNAME = [ "hel0.nichi.link." ];
  };
}
