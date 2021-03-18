{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-03-18";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "e5ae7c0f3b80dff74e5827352fe33128fa8e6dac"; # heads/release
    sha256 = "1g4nz97q2v7d07p6bx2jmwqlhpm71aa4xaajvi9v5biqzp15q3b4";
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
