{ dns }:
with dns.lib.combinators;
let
  nodes = (builtins.fromJSON (builtins.readFile ./nodes.json)).nodes.value;
in
dns.lib.toString "nichi.link" {
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
  subdomains = builtins.mapAttrs (name: value: host value.ipv4 value.ipv6) nodes // {
    "nrt.jp".CNAME = [ "nrt0.nichi.link." ];
    "sin.sg".CNAME = [ "sin0.nichi.link." ];
  };
}
