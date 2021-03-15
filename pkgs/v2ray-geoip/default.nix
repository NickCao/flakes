{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-03-15";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "c9a2b15844382d1637aff20cbacf107f9192b507"; # heads/release
    sha256 = "0kir02r7svwvbrvaal75m4pm1cixzjxjyszwsqaiv22142dpqxm9";
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
