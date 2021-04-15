{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-04-15";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "f0200c7a86b1a19b10d543fa7ae130c41e3d0f78"; # heads/master
    sha256 = "18wdjy65hih8a2amn1q292pv980g6xdxrdsvl9gpdk0dcqmbw06y";
  };

  vendorSha256 = "sha256-jv2Dh4v4EAzoaoemQbuBaj+kaMzKvlm69R4qQY8Ee0M=";

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
