{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-18";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "2c10ce5cd2d481d6fd5cfd8038a3052b7a091890"; # heads/master
    sha256 = "13fab2hz2x7z2rbb799h0y005n2q06cgii29ak2k6g8rzgb74rff";
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
