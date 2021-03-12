{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-11";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "27818909a41ac78aaa7a2179ee8b5ae0e1d23a4a"; # heads/master
    sha256 = "1g4v0dlyylgpkqbdm53xaxrl8b4fwhsnjjxx08hw8r1m8y1xhwmk";
  };

  vendorSha256 = "sha256-7GGnS6h2mE8p+Swaqr7htHgdvqzoCpfcC8Un1mBHLnA=";

  outputs = [ "out" "data" ];

  postInstall = ''
    $out/bin/domain-list-community -datapath $src/data --exportlists=category-ads-all,tld-cn,cn,tld-\!cn,geolocation-\!cn,apple,icloud
    install -Dm644 dlc.dat $data/share/v2ray/geosite.dat
  '';

  meta = with lib; {
    description = "community managed domain list";
    homepage = "https://github.com/v2fly/domain-list-community";
    license = licenses.mit;
    outputsToInstall = [ "data" ];
  };
}
