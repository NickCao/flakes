let data = builtins.fromJSON (builtins.readFile ./data.json);
in
{
  TTL = 30;
  SOA = {
    nameServer = "hel0.nichi.link.";
    adminEmail = "noc@nichi.co";
    serial = 0000000000;
    refresh = 600;
    retry = 600;
    expire = 86400;
    minimum = 300;
  };
  NS = builtins.map (name: "${name}.") data.nameservers.value;
  nodes = data.nodes.value;
}
