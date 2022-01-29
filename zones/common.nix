{
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
    "hydrogen.ns.hetzner.com."
    "oxygen.ns.hetzner.com."
    "helium.ns.hetzner.de."
  ];
}
