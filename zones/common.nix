let
  data = builtins.fromJSON (builtins.readFile ./data.json);
in
{
  TTL = 30;
  SOA = {
    nameServer = "iad0.nichi.link.";
    adminEmail = "noc@nichi.co";
    serial = 0;
    refresh = 14400;
    retry = 3600;
    expire = 604800;
    minimum = 300;
  };
  NS = builtins.map (name: "${name}.") data.nameservers.value;
  DMARC = [
    {
      p = "reject";
      sp = "reject";
      pct = 100;
      adkim = "strict";
      aspf = "strict";
      fo = [ "1" ];
      ri = 604800;
    }
  ];
  CAA = [
    {
      issuerCritical = false;
      tag = "issue";
      value = "letsencrypt.org";
    }
  ];
  SRV = [
    {
      service = "imaps";
      proto = "tcp";
      port = 993;
      target = "iad0.nichi.link.";
    }
    {
      service = "submissions";
      proto = "tcp";
      port = 465;
      target = "iad0.nichi.link.";
    }
  ];
  nodes = data.nodes.value;
  secondary_nameservers = data.secondary_nameservers.value;
}
