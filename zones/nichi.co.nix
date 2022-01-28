{ dns }:
with dns.lib.combinators;
let
  inherit ((builtins.fromJSON (builtins.readFile ./nodes.json)).nodes.value) nrt0;
in
dns.lib.toString "nichi.co" {
  TTL = 30;
  SOA = {
    nameServer = "sea0.nichi.link.";
    adminEmail = "noc@nichi.co";
    serial = 0000000000;
    refresh = 600;
    retry = 600;
    expire = 86400;
    minimum = 300;
  };
  NS = [
    "sea0.nichi.link."
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
    pb.CNAME = [ "hel0.nichi.link." ];
    s3.CNAME = [ "hel0.nichi.link." ];
    stats.CNAME = [ "hel0.nichi.link." ];
    hydra.CNAME = [ "hel0.nichi.link." ];
    vault.CNAME = [ "hel0.nichi.link." ];
    tagging.CNAME = [ "hel0.nichi.link." ];
    www.TXT = [ "http.cat/404" ];
  };
}
