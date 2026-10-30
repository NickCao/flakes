{ dns }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  he = builtins.map (x: "ns${builtins.toString x}.he.net.") (builtins.genList (x: x + 1) 5);
in
dns.lib.toString "scp.link" {
  inherit (common)
    TTL
    SOA
    NS
    CAA
    ;
  # stalwart
  MX = with mx; [ (mx 10 "hel1.nichi.link.") ];
  TXT = with spf; [ (strict [ "mx" ]) ];

  subdomains = {
    # stalwart
    "ua-auto-config".CNAME = [ "hel1.nichi.link." ];
    "_ua-auto-config".TXT = [
      "v=UAAC1; a=sha256; d=5AxaZQTZ9WSSH1/AhLwMORH6s3hrdf21aLw9Fkt6Te8=" # FIXME
    ];
    "mta-sts".CNAME = [ "hel1.nichi.link." ];
    "_mta-sts".TXT = [
      "v=STSv1; id=5685670329720542694" # FIXME
    ];

    "mail".CNAME = [ "hel1.nichi.link." ];
    "o".NS = he;
    "com".NS = he;
    "t".NS = he;
  };
}
