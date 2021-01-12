{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-01-11";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "c278c257243aae63ea61343522706a40b36f14f0"; # heads/master
    sha256 = "028r82wh3yvb4jy5rz9vgmbyzw6k13mcnqnsi6b7l52psyj0lbhi";
  };

  vendorSha256 = "sha256-bWEJ6PgkmQo5ZoZqt2FU7i9x4lPo70DbZ2FSwdnHlxw=";

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
