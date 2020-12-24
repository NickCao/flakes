{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2020-12-23";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "60f5b723e0cc7452388b2821de2413800a990c0d"; # master
    sha256 = "167d8bryj0b8v2hlw4g05qvixr4fnwxaw4k56y97dav1z98yywfx";
  };

  vendorSha256 = "sha256-6YIRA6xBFrb5s3drVTSPLvN0wKdtgNvSCEZ8r6samxw=";

  outputs = [ "out" "data" ];

  postInstall = ''
    $out/bin/domain-list-community -datapath $src/data --exportlists=category-ads-all,tld-cn,cn,tld-\!cn,geolocation-\!cn,apple,icloud
    install -m 644 dlc.dat -D $data/share/v2ray/geosite.dat
  '';

  meta = with lib; {
    description = "community managed domain list";
    homepage = "https://github.com/v2fly/domain-list-community";
    license = licenses.mit;
    outputsToInstall = [ "data" ];
  };
}
