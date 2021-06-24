{ dns }:
with dns.lib.combinators;
let
  nodes = (builtins.fromJSON (builtins.readFile ./nodes.json)).nodes.value;
in
dns.lib.toString "nichi.link" {
  TTL = 30;
  SOA = {
    nameServer = "las0.nichi.co.";
    adminEmail = "noc@nichi.co";
    serial = 2021062400;
    refresh = 10000;
    retry = 2400;
    expire = 604800;
    minimum = 60;
  };
  NS = [
    "las0.nichi.link."
    "nrt0.nichi.link."
    "sin0.nichi.link."
  ];
  subdomains = builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes // {
    "nrt.jp".CNAME = [ "nrt0.nichi.link." ];
    "sin.sg".CNAME = [ "sin0.nichi.link." ];
    ns1.CNAME = [ "nrt0.nichi.link." ];
    ns2.CNAME = [ "sin0.nichi.link." ];
  };
}
