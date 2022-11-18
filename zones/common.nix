let data = builtins.fromJSON (builtins.readFile ./data.json);
in
{
  TTL = 30;
  SOA = {
    nameServer = "iad0.nichi.link.";
    adminEmail = "noc@nichi.co";
    serial = 0000000000;
    refresh = 14400;
    retry = 3600;
    expire = 604800;
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
    p = "reject";
    sp = "reject";
    pct = 100;
    adkim = "strict";
    aspf = "strict";
    fo = [ "1" ];
    ri = 604800;
    ruf = [ "mailto:postmaster@nichi.co" ];
    rua = [ "mailto:postmaster@nichi.co" ];
  }];
  CAA = [{
    issuerCritical = false;
    tag = "issue";
    value = "letsencrypt.org";
  }];
  SRV = [
    {
      service = "imaps";
      proto = "tcp";
      port = 993;
      target = "iad0.nichi.link.";
    }
    {
      service = "submission";
      proto = "tcp";
      port = 465;
      target = "iad0.nichi.link.";
    }
  ];
  nodes = data.nodes.value;
}
