{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-22";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "422452ffc3dbb4b74f5ed2c07ab56da850a8bce3"; # heads/master
    sha256 = "1lpsdhbzwvk0g9h96w14ak4xfbrhff25zzjl2mbqi41il6piyy7h";
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
