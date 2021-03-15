{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-15";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "e03d2c52bbbbed031fca46ccf5815db4c8a22b83"; # heads/master
    sha256 = "0awhp0ij1pz52bkq7lsd3h6x4218i7hww8fhpkxgpr36wlag0nhw";
  };

  vendorSha256 = "sha256-P8KmRJrH1ljkt7eZgWcIcec16tKRHEKoTFGlX05mWb4=";

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
