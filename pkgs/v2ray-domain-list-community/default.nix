{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-22";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "6e64c8fb4486fb57236719db8d51701c2bc326fb"; # heads/master
    sha256 = "0bpzm1xx1k9rv6c756lzlfricfh0ilrz0wb70mg4z1snbc70acnr";
  };

  vendorSha256 = "sha256-ZrwYrmPwbqVXudU4hgyHktcvLY2Tecqq4R9/AcUSRZ4=";

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
