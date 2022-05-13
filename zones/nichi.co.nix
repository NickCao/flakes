{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.nodes) nrt0;
in
dns.lib.toString "nichi.co" {
  inherit (common) TTL SOA NS;
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
    (mx 10 "hel0.nichi.link.")
  ];
  TXT = [
    (with spf; soft [ "mx" ])
  ];
  DKIM = [{
    selector = "default";
    k = "rsa";
    p = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzZQePdABnCiCpmzMxfrg6Bta/bLEMzyVuaa/FH+XE6bmLUxIgr6FqhdeZhZzCMG/LZWKSnncKGd3TMobFi4/mrpqmfFpO/8FRfUh8X7spe8TVTkSOStIT2ePtDU/XNsagafej3Ot3hUKHxuVeGWUsRB8IVRoyQZ86YK27wR4z/XmV3t3xerhOEBhrL7r5volfI3dOKrwgFuIPp0OxZEpcSDVsavQeaZ+K9uKN44m8tEBzVpnh5UXxBhveliRMptBxk9WUxwqoD+Yo4epQwm+xkNeCSe/hKlD8icLbetXXmi2PD12ngIhs1WPMvH/+LrT5NkDZuETKj9tRBbIOqlhpQIDAQAB";
    s = [ "email" ];
  }];
  DMARC = [{
    p = "quarantine";
    sp = "reject";
    pct = 100;
    adkim = "strict";
    aspf = "strict";
  }];
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
    api = host nrt0.ipv4 nrt0.ipv6;
    fn.CNAME = [ "nrt0.nichi.link." ];
    git.CNAME = [ "hel0.nichi.link." ];
    live.CNAME = [ "hel0.nichi.link." ];
    matrix.CNAME = [ "hel0.nichi.link." ];
    pb.CNAME = [ "hel0.nichi.link." ];
    hydra.CNAME = [ "hel0.nichi.link." ];
    vault.CNAME = [ "hel0.nichi.link." ];
    cache.CNAME = [ "hel0.nichi.link." ];
    tagging.CNAME = [ "hel0.nichi.link." ];
    www.TXT = [ "http.cat/404" ];
  };
}
