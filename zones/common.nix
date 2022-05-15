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
  DKIM = [{
    selector = "default";
    k = "rsa";
    p = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC+6z/8WkmYxW0mT88OLyre9HP5YPF0iaEaGF33loWzzA6gwnW0PVGaL/TObcEUg7w0ocmuzt/fBqwtvUIo5W8aA78dZy9o07PxDiibtqQrvooJdgzJAH4ISJe8W/slacX+z6SfqajIR/MQh8v1SjHzPiGsN+TAbEtrXLxij6TvVwIDAQAB";
    s = [ "email" ];
  }];
  DMARC = [{
    p = "quarantine";
    sp = "reject";
    pct = 100;
    adkim = "strict";
    aspf = "strict";
  }];
  nodes = data.nodes.value;
}
