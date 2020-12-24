{ mkDerivation, fetchFromGitHub, lib, cmake }:

mkDerivation rec {
  pname = "qv2ray-plugin-ssr";
  version = "2020-12-14";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SSR";
    rev = "6f4f87e3377ec3bb335d87464806edaad92bd639"; #dev
    fetchSubmodules = true;
    sha256 = "14h2pz4sjn5v640s38zgyx4xzbymnwf3i4ylghfscpikgax8vb1w";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "ShadowsocksR plugin for Qv2ray";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
}
