{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-05-13";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "f8cadad53e663f6aca900700b0f48dd3a86749fa"; # heads/release
    sha256 = "0dkkxvw7dwfa9q87im2iq7086gr8cb3ca7flpinw2l7cdqs983w9";
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
