{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-04-19";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "c5c939c25e8ee14651daff51273ff341068dadf5"; # heads/master
    sha256 = "0l7rrmsbz45sf61vkkgkjms444wvh69l5xhfh5d8qvrkbc4mhs6r";
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
