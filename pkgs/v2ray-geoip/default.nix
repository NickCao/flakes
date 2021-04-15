{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-04-15";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "afa8b70a4ee75f47c3bb31979ad46831711157bd"; # heads/release
    sha256 = "0mixlrqg6hsm1r699knryfqi78dfrnbv8x3d10m7nx9shx04ajlj";
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
