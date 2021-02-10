{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-02-06";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "e5b1a96bee2f514f269b2629235a71357e411264"; # heads/master
    sha256 = "14s06xinx6xk42f6c31csv95xa7ysd6qnnhh4nyzfxfiz50n7n2d";
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
