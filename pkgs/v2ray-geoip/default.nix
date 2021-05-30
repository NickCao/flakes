{ source, fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  inherit (source) pname version src;

  installPhase = ''
    install -m 0644 geoip.dat -D $out/share/v2ray/geoip.dat
  '';

  meta = with lib; {
    description = "geoip for v2ray";
    homepage = "https://github.com/v2fly/geoip";
    license = licenses.cc-by-sa-40;
  };
}
