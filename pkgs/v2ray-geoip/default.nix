{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-03-11";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "fde6a7ee8cad4a2afe09a4ad026c6fa46cfdaede"; # heads/release
    sha256 = "0wq7dzmgix9adrihi9xn8knsv5ln0nfi4b1a5cn3jizlrl9f76q1";
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
