{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.nodes) nrt0;
in
dns.lib.toString "nichi.co" {
  inherit (common) TTL SOA NS DKIM DMARC CAA;
  A = [ nrt0.ipv4 ];
  AAAA = [ nrt0.ipv6 ];
  MX = with mx; [
    (mx 10 "hel0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  SRV = [
    {
      service = "imaps";
      proto = "tcp";
      port = 993;
      target = "hel0.nichi.link.";
    }
    {
      service = "submission";
      proto = "tcp";
      port = 465;
      target = "hel0.nichi.link.";
    }
  ];
  subdomains = {
    www.TXT = [ "http.cat/404" ];
    fn.CNAME = [ "nrt0.nichi.link." ];
    pb.CNAME = [ "hel0.nichi.link." ];
    api.CNAME = [ "nrt0.nichi.link." ];
    git.CNAME = [ "hel0.nichi.link." ];
    red.CNAME = [ "hel0.nichi.link." ];
    hydra.CNAME = [ "hel0.nichi.link." ];
    vault.CNAME = [ "hel0.nichi.link." ];
    cache.CNAME = [ "hel0.nichi.link." ];
    matrix.CNAME = [ "hel0.nichi.link." ];
  };
}
