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
    _dmarc.TXT = [
      "v=DMARC1; p=quarantine; rua=mailto:postmaster@scp.link"
    ];
    _tls.subdomains._smtp.TXT = [
      "v=TLSRPTv1; rua=mailto:postmaster@scp.link"
    ];
    _domainkey.subdomains = {
      v1-ed25519-20261030.TXT = [
        "v=DKIM1; k=ed25519; h=sha256; p=pQNEIJY3bTfTNSBzUwtsQlYsA6o31Ob5kN/xdR+4lpM="
      ];
      v1-rsa-20261030.TXT = [
        "v=DKIM1; k=rsa; h=sha256; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvlE1+J2GmcJ+jgb4QvTx2qIaDgwlYohjd1zMAQh6iHPCX20Ryjqt1b0Ur5KAgKnul4ueJzLzorFMgkYtqnplC3EcB/Et7MG3TfhyxXw8b94hLR7/Fsm2zOuB2KNXOoIFh/u0v/TBK+3TatlnStheyLv/XA3pPIViTwhatRJAnVzFTIcd+hVVS+C9f1xjA2FSSFE3dbVDcdW9nejWLyQk41n71bI58gqFMzyywBfMJ7DyRxMcNBf0i1uF3Nx/Bd221GKDZ7YWGyH5ib1/Pa/uN6Zx9P/j9I7p9D5/5nLmdEnuNj+AqxJJhZ8Z2i07q5+GAJL5Gv+wUOrPJlecsRCRdQIDAQAB"
      ];
    };

    "mail".CNAME = [ "hel1.nichi.link." ];
    "o".NS = he;
    "com".NS = he;
    "t".NS = he;
  };
}
