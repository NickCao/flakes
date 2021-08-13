{ dns }:
with dns.lib.combinators;
let
  nrt0 = (builtins.fromJSON (builtins.readFile ./nodes.json)).nodes.value.nrt0;
in
dns.lib.toString "nichi.co" {
  TTL = 30;
  SOA = {
    nameServer = "las0.nichi.link.";
    adminEmail = "noc@nichi.co";
    serial = 2021062400;
    refresh = 14400;
    retry = 3600;
    expire = 604800;
    minimum = 300;
  };
  NS = [
    "las0.nichi.link."
    "nrt0.nichi.link."
    "sin0.nichi.link."
  ];
  A = [ nrt0.ipv4 ];
  AAAA = [ nrt0.ipv6 ];
  CAA = [
    {
      issuerCritical = false;
      tag = "issue";
      value = "letsencrypt.org";
    }
    {
      issuerCritical = false;
      tag = "issue";
      value = "sectigo.com";
    }
  ];
  MX = with mx; [
    (mx 10 "in1-smtp.messagingengine.com.")
    (mx 20 "in2-smtp.messagingengine.com.")
  ];
  TXT = [
    (with spf; soft [ "include:spf.messagingengine.com" ])
  ];
  subdomains = {
    s3.CNAME = [ "hel0.nichi.link." ];
    stats.CNAME = [ "hel0.nichi.link." ];
    www.TXT = [ "http.cat/404" ];
    "*".CNAME = [ "nichi.co." ];
    "fm1._domainkey".CNAME = [ "fm1.nichi.co.dkim.fmhosted.com." ];
    "fm2._domainkey".CNAME = [ "fm2.nichi.co.dkim.fmhosted.com." ];
    "fm3._domainkey".CNAME = [ "fm3.nichi.co.dkim.fmhosted.com." ];
  };
}
