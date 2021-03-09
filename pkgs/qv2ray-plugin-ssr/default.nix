{ qt5, fetchFromGitHub, lib, cmake, libsodium, libuv }:

with qt5;
mkDerivation rec {
  pname = "qv2ray-plugin-ssr";
  version = "2020-12-14";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SSR";
    rev = "6f4f87e3377ec3bb335d87464806edaad92bd639"; # heads/dev
    fetchSubmodules = true;
    sha256 = "14h2pz4sjn5v640s38zgyx4xzbymnwf3i4ylghfscpikgax8vb1w";
  };

  cmakeFlags = [
    "-DUSE_SYSTEM_SODIUM=ON"
    "-DUSE_SYSTEM_LIBUV=ON"
    "-DLibUV_LIBRARY=${libuv}/lib/libuv.so"
    # workaroud for badly written cmake
    "-DQV_QT_MAJOR_VERSION=5"
    "-DQV_QT_MINOR_VERSION=0"
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ libsodium libuv ];

  meta = with lib; {
    description = "ShadowsocksR plugin for Qv2ray";
    homepage = "https://github.com/Qv2ray/QvPlugin-SSR";
    license = licenses.gpl3Only;
  };
}
