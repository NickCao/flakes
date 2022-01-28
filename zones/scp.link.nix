{ dns }:
with dns.lib.combinators;
dns.lib.toString "scp.link" {
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
  subdomains = {
    "o".NS = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
    vanilla.A = [ "159.65.135.68" ];
  };
}
