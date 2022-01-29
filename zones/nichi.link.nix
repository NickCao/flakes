{ dns }:
with dns.lib.combinators;
let
  nodes = (builtins.fromJSON (builtins.readFile ./nodes.json)).nodes.value;
  common = import ./common.nix;
in
dns.lib.toString "nichi.link" {
  inherit (common) TTL SOA NS;
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
  subdomains = builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes // {
    "hel0" = host "65.21.32.182" "2a01:4f9:3a:40c9::1";
    "nrt.jp".CNAME = [ "nrt0.nichi.link." ];
    "sin.sg".CNAME = [ "sin0.nichi.link." ];
    "rpi".CNAME = [ "rpi.dyn.nichi.link." ];
  };
}
