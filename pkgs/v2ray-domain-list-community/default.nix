{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule {
  pname = "v2ray-domain-list-community";
  version = "2021-03-08";

  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "domain-list-community";
    rev = "7d99316498890c14a0b5e811976877546068ab3b"; # heads/master
    sha256 = "0vkkii5cyrqaab5z36rlmjjyh6xrnik4iv7y9ix2scxqwxq11zm1";
  };

  vendorSha256 = "sha256-7GGnS6h2mE8p+Swaqr7htHgdvqzoCpfcC8Un1mBHLnA=";

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
