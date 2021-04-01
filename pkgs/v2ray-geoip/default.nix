{ fetchFromGitHub, stdenv, lib }:

stdenv.mkDerivation {
  pname = "v2ray-geoip";
  version = "2021-04-01";
  src = fetchFromGitHub {
    owner = "v2fly";
    repo = "geoip";
    rev = "a5ee174b3fbea5b781c95944aa60eca61ea396c4"; # heads/release
    sha256 = "03kj6mmhllb81fgz47si98jli998z7mdkisvz6a84z7f439gii4d";
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
