{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-03-08";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "7fc41f5cd05926f39da95c53aba2a85280c0ad5f"; # heads/release
    sha256 = "1iwxyl6a8lnbwcgm8m3ypxd3bq1lg4c58dqjn4956jib13w2f2nw";
  };

  installPhase = ''
    install -m 0644 geoip.dat -D $out/share/v2ray/geoip.dat
  '';

  meta = with lib; {
    description = "geoip for v2ray";
    homepage = "https://github.com/v2fly/geoip";
    license = licenses.cc-by-sa-40;
  };
}
