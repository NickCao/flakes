{ fetchurl, stdenv, lib }:

stdenv.mkDerivation rec {
  pname = "v2ray-geoip";
  version = "202012240026";
  srcs = fetchurl {
    url =
      "https://github.com/v2fly/geoip/releases/download/${version}/geoip.dat";
    sha256 = "sha256-T8yCJZ5t1C20b6FCiFrILzFIsJkpWcH3FvOTgvejk60=";
  };

  unpackCmd = ''
    install -m 0644 $curSrc -D src/$(stripHash $curSrc)
  '';

  installPhase = ''
    install -m 0644 geoip.dat -D $out/share/v2ray/geoip.dat
  '';

  meta = with lib; {
    description = "geoip for v2ray";
    homepage = "https://github.com/v2fly/geoip";
    license = licenses.cc-by-sa-40;
  };
}
