{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-31";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "21c2be140309f2013482dd4a08ff2c03289acefc"; # heads/master
    sha256 = "1vmha9krm55w8qygpmrzdfp04wh373x5iybgs7j3068v5ydjzrai";
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
