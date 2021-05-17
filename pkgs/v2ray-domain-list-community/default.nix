{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-05-08";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "944a3d3be86ee814fa0eaf1759f8d18bb0b94e79"; # heads/master
    sha256 = "036ncywa2mjkhlqjwjr9g7a5m74ji9dkz0xvk9df3mp352z7qncs";
  };

  vendorSha256 = "sha256-IhIRXdiwzvvT5aIEiLbrUoTfy/OPveIjXJXck5N9iQg=";

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
