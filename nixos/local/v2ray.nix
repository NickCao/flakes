{
  log = { loglevel = "warning"; };
  observatory = { probeInterval = "1m"; probeURL = "https://example.com"; subjectSelector = [ "proxy" ]; };
  inbounds = [
    {
      listen = "127.0.0.1";
      port = 8888;
      protocol = "http";
      sniffing = { destOverride = [ "http" "tls" ]; enabled = true; metadataOnly = false; };
      tag = "http";
    }
    {
      listen = "127.0.0.1";
      port = 1080;
      protocol = "socks";
      sniffing = { destOverride = [ "http" "tls" ]; enabled = true; metadataOnly = false; };
      tag = "socks";
    }
  ];
  routing = {
    domainMatcher = "mph";
    domainStrategy = "IPIfNonMatch";
    rules = [
      { domains = [ "geosite:cn" ]; outboundTag = "direct"; type = "field"; }
      { ip = [ "geoip:private" "geoip:cn" ]; outboundTag = "direct"; type = "field"; }
      { balancerTag = "balancer"; network = "tcp,udp"; type = "field"; }
    ];
    balancers = [
      { selector = [ "proxy" ]; strategy = { type = "leastPing"; }; tag = "balancer"; }
    ];
  };
}
